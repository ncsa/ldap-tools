#!___INSTALL_DIR___/.venv/bin/python3

# Report etime statistics on LDAP actions from
# LDAP access events (from JSON as output by LAP)

import argparse
import datetime
import fileinput
import json
import logging
import pandas as pd
import syslog
import textwrap
import time

from functools import wraps

# module level variables
resources = {}

def get_args( params=None ):
    key = 'args'
    if key not in resources:
        constructor_args = {
            'formatter_class': argparse.ArgumentDefaultsHelpFormatter,
            'description': textwrap.dedent( '''\
                Summarize etimes from LDAP access events.
                ''')
            }
        parser = argparse.ArgumentParser( **constructor_args )
        # normal options
        parser.add_argument( '-d', '--debug', action='store_true' )
        parser.add_argument( '-v', '--verbose', action='store_true' )
        parser.add_argument( '-z', '--timezone',
            default='US/Central',
            help='Timezone used in log timestamps.',
            )
        parser.add_argument( 'infiles', nargs='*', default='-' )
        # input filter vars
        TS_FORMAT='%Y-%m-%d:%H:%M:%S'
        action_options = [
            'ABANDON',
            'ADD',
            'BIND',
            'CMP',
            'DEL',
            'EXT',
            'MOD',
            'MODRDN',
            'SRCH',
            'UNBIND',
            ]
        # input filter options
        input_filters = parser.add_argument_group( 'Input Filtering' )
        input_filters.add_argument( '-a', '--action', action='append',
            dest='actions',
            choices=action_options,
            default=[ 'SRCH' ],
            help=f'''Only report on these actions.
                    Can be specified multiple times.
                ''',
            )
        # output format options
        output_args = parser.add_argument_group( 'Output Formatting' )
        output_args.add_argument( '-S', '--syslog', action='store_true',
            help='''
                Send summary records to syslog.
                Note this is independent of --format.
            '''
            )
        output_args.add_argument( '-F', '--format',
            choices=[ 'csv', 'json', 'text' ],
            help='''
                If set, print output to stdout in this format.
                Default: Don't print anything.
                Note this is independent of --syslog.
            '''
            )
        output_args.add_argument( '--showall', action='store_true',
            help='When format=text, show all records instead of truncating',
            )
        # Hidden options
        # script start time
        parser.add_argument('--start_time', help=argparse.SUPPRESS, default=time.time() )
        # process cmdline
        args = parser.parse_args( params )
        # save
        resources[key] = args
    return resources[key]


def get_warnings():
    key = 'warnings'
    if key not in resources:
        resources[key] = []
    return resources[key]


def warn( msg ):
    ''' Log a warning to the screen and,
        Also save it in an array for later retrieval of all warnings.
    '''
    key = 'warnings'
    if key not in resources:
        resources[key] = []
    resources[key].append( msg )
    logging.warning( msg )


def get_errors():
    key = 'errs'
    if key not in resources:
        resources[key] = []
    return resources[key]


def err( msg ):
    ''' Log an error to the screen and,
        Also save it in an array for later retrieval of all errors.
    '''
    key = 'errs'
    if key not in resources:
        resources[key] = []
    resources[key].append( msg )
    logging.error( msg )

# https://stackoverflow.com/questions/1622943/timeit-versus-timing-decorator#27737385
def timing( f ):
    @wraps( f )
    def wrap( *args, **kw ):
        starttime = time.time()
        result = f( *args, **kw )
        endtime = time.time()
        elapsed = endtime - starttime
        logging.info( f'func:{f.__name__} args:[{args}, {kw}] took: {elapsed} sec' )
        return result
    return wrap


def get_events():
    key = 'events'
    if key not in resources:
        resources[key] = []
    return resources[key]


def add_event(e):
    keys = [ 'time', 'action', 'etime' ]
    new_e = { k: e[k] for k in keys }
    get_events().append( new_e )


def attr_from_result( record, attr, cast_func=int, default=0 ):
    ''' extract an attribute from the Response.
        In the record, Responses is an array.
        In case of multiple Responses, get the max.
        cast_func - callable that will convert string to the appropriate type
    '''
    vals = []
    attr_len = len( attr ) + 1
    rv = default
    for line in record['responses']:
        for part in line.split():
            if part.startswith( f'{attr}=' ):
                val = part[attr_len:]
                vals.append( cast_func( val ) )
    try:
        rv = max( vals )
    except ValueError:
        pass
    return rv


def fixup_record( r ):
    ''' Add custom mods to record; such as etime
        Convert str fields to native types; such as time 
    '''
    # time (convert to datetime)
    dtformat = '%d/%b/%Y:%H:%M:%S.%f %z'
    r[ 'time' ] = pd.to_datetime( r[ 'time' ], format=dtformat )
    # etime (extract & convert to float)
    r[ 'etime' ] = attr_from_result( r, 'etime', cast_func=float )
    # # err (extract & convert to int)
    # r[ 'err' ] = attr_from_result( r, 'err' )
    # # nentries (extract & convert to int)
    # r[ 'nentries' ] = attr_from_result( r, 'nentries' )


@timing
def process_json_events():
    args = get_args()
    # count = 0
    num_records = 0
    num_thousands = 0
    for line in fileinput.input( args.infiles ):
        num_records += 1
        if (num_records % 1000) == 0 :
            num_thousands += 1
            logging.debug( num_thousands )
        record = json.loads( line )
        # Add custom fields and convert as needed
        fixup_record( record )
        # # filter on etime
        # if record['etime'] < args.etime:
        #     continue
        # filter on action
        if args.actions and record['action'] not in args.actions:
            continue
        # filter on client
        # if args.include_clients:
        #     if record['client'] not in args.include_clients:
        #         continue
        # if args.exclude_clients:
        #     if record['client'] in args.exclude_clients:
        #         continue
        add_event( record )


def mk_summaries():
    df = pd.DataFrame( get_events() )
    # round up timestamp at 5 min intervals
    df[ 'rounded_timestamp' ] = df[ 'time' ].dt.ceil( '5min' )
    # print( df )
    grouped = df.groupby( [ 'rounded_timestamp', 'action' ] )
    # calculate aggregations for etime
    result = grouped['etime'].agg(
        min=('min'),
        median=('median'),
        max=('max'),
        count=('count'),
        count_gt_5=( lambda x: (x > 5).sum() ),
        count_gt_10=( lambda x: (x > 10).sum() ),
    )

    # could also add etime aggregations this way, which might be useful
    # if aggregating on a different field (ie: grouped['action'] or something)
    #result['count_gt_5'] = grouped['etime'].apply( lambda x: (x > 5).sum() )
    #result['count_gt_10'] = grouped['etime'].apply( lambda x: (x > 10).sum() )

    return result.reset_index()


def send_to_syslog( df ):
    ''' Expects a pandas dataframe for input
    '''
    ident = 'ldap_etime_summary'
    lines = df.to_json( orient='records', lines=True, date_format='iso' ).splitlines()
    syslog.openlog( ident )
    for line in lines:
        syslog.syslog( line )
    syslog.closelog()


def print_records( df ):
    ''' Expects a pandas dataframe for input
    '''
    args = get_args()
    if args.format == 'csv':
        print( df.to_csv() )
    elif args.format == 'json':
        print( df.to_json() )
    elif args.showall:
        # these are the defaults
        display_options = [ 'display.max_rows', None, 'display.max_columns', None ]
        with pd.option_context( *display_options ):
            print( df )
    else:
        print( df )


def print_runtime():
    args = get_args()
    end_time = time.time()
    elapsed = end_time - args.start_time
    runtime = datetime.timedelta( seconds=elapsed )
    logging.info( f'Runtime: {runtime}' )


def run():
    args = get_args()

    process_json_events()

    summary_data = mk_summaries()

    if args.syslog:
        send_to_syslog( summary_data )
    if args.format:
        print_records( summary_data )

    if args.verbose:
        print_runtime()


if __name__ == '__main__':
    args = get_args()
    loglvl = logging.WARNING
    if args.verbose:
        loglvl = logging.INFO
    if args.debug:
        loglvl = logging.DEBUG
    logfmt = '%(levelname)s:%(funcName)s[%(lineno)d] %(message)s'
    logging.basicConfig( level=loglvl, format=logfmt )
    logging.debug( args )
    run()
