#!___INSTALL_DIR___/.venv/bin/python3

# Filter and parse LDAP access events (from JSON as output by LAP)

import pandas as pd
import argparse
import fileinput
import json
import pprint
import collections
import logging
import textwrap
import time
import datetime

from functools import wraps

# module defined types
nested_dict = lambda: collections.defaultdict( nested_dict )

# module level variables
resources = {}

def get_args( params=None ):
    key = 'args'
    if key not in resources:
        constructor_args = {
            'formatter_class': argparse.ArgumentDefaultsHelpFormatter,
            'description': textwrap.dedent( '''\
                Filter and parse LDAP access events.
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
        # action_defaults = action_options
        # input filter options
        input_filters = parser.add_argument_group( 'Input Filtering' )
        input_filters.add_argument( '-a', '--action', action='append',
            dest = 'actions',
            choices=action_options,
            help=f'''Only report on these actions.
                    Can be specified multiple times.
                ''',
            )
        input_filters.add_argument( '-e', '--etime', type=float,
            default=0,
            help='Ignore etimes less than ETIME.',
            )
        input_filters.add_argument( '-i', '--include_client', action='append',
            dest='include_clients',
            help='''Include events from these client IPs only.
                    Can be specified multiple times.
                    If left empty, all clients will be reported.
                ''',
            )
        input_filters.add_argument( '-x', '--exclude_client', action='append',
            dest='exclude_clients',
            help='''Exclude events from these client IPs.
                    Can be specified multiple times.
                    If left empty, all clients will be reported.
                ''',
            )
        input_filters.add_argument( '-n', '--notes', action='append',
            help='''Show only logs that have this/these note codes.
                    Can be specified multiple times.
                    See LDAP docs for valid note codes.
                ''',
            )
        input_filters.add_argument( '-u', '--unindexed', action='store_true',
            help='''Show only logs that report unindexed actions.'''
            )
        input_filters.add_argument( '-t', '--timestamp',
            help=f'''Show only logs that are within num SECS of this TIMESTAMP.
                Format as {TS_FORMAT.replace('%','%%')}.
                See also -A, -B, (--after, --before).
                ''',
            )
        input_filters.add_argument( '-A', '--after', metavar='SECS',
            type=float,
            default=1,
            help='''If --timestamp is specified,
                    only include logs that occur num SECS after TIMESTAMP.
                    Can be used alongside -B.
                ''',
            )
        input_filters.add_argument( '-B', '--before', metavar='SECS',
            type=float,
           default=1,
            help='''If --timestamp is specified,
                    only include logs that occur num SECS before TIMESTAMP.
                    Can be used alongside -A.
                ''',
            )
        # output format vars
        output_field_defaults = \
            'time,client,action,etime,nentries,requests,responses'.split(',')
        output_field_options = \
            output_field_defaults + \
            [ 'connection', 'operation', 'server', 'ssl', 'err' ]
        # output format options
        output_args = parser.add_argument_group( 'Output Formatting' )
        output_args.add_argument( '-f', '--field', action='append',
            dest='fields',
            default=[],
            choices=output_field_options + ['ALL'],
            help=f''' Event fields to output.
                Defaults to: {output_field_defaults}
                ''',
            )
        output_args.add_argument( '-F', '--format',
            choices=[ 'csv', 'json', 'text' ],
            default='text',
            help='set output format',
            )
        output_args.add_argument( '--showall', action='store_true',
            help='When format=text, show all records instead of truncating',
            )
        output_args.add_argument( '--groupby_sum', action='store_true',
            help='''
                When format=text,
                group by field 1, sum of field 2,
                where fields 1 & 2 are specified by the -f option.
                ''',
            )
        # Hidden options
        # calculate tsmin and tsmax from timestamp and timedelta during post processing
        parser.add_argument('--tsmin', help=argparse.SUPPRESS, default='0')
        parser.add_argument('--tsmax', help=argparse.SUPPRESS, default='4102380000')
        # script start time
        parser.add_argument('--start_time', help=argparse.SUPPRESS, default=time.time() )

        # process cmdline
        args = parser.parse_args( params )

        # post processing - calculate output fields
        if 'ALL' in args.fields:
            args.fields = output_field_options
        elif len( args.fields ) < 1:
            args.fields = output_field_defaults
        # post processing - calculate start and end timestamps
        if args.timestamp:
            base_ts = pd.to_datetime( args.timestamp, format=TS_FORMAT )
            before = pd.to_timedelta( args.before, unit='s' )
            after = pd.to_timedelta( args.after, unit='s' )
            args.tsmin = base_ts - before
            args.tsmax = base_ts + after
        else:
            args.tsmin = pd.to_datetime( args.tsmin, unit='s' )
            args.tsmax = pd.to_datetime( args.tsmax, unit='s' )
        args.tsmin = args.tsmin.tz_localize( args.timezone )
        args.tsmax = args.tsmax.tz_localize( args.timezone )
        # post processing - unindexed actions
        if args.unindexed:
            if args.notes is None:
                args.notes = []
            args.notes.extend( [ 'U', 'A' ] )

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
    cleanup( e, get_args().fields )
    get_events().append( e )


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
    ''' Add custom mods to record; such as etime, notes
        Convert str fields to native types; such as time 
    '''
    # time (convert to datetime)
    dtformat = '%d/%b/%Y:%H:%M:%S.%f %z'
    r[ 'time' ] = pd.to_datetime( r[ 'time' ], format=dtformat )
    # etime (extract & convert to float)
    r[ 'etime' ] = attr_from_result( r, 'etime', cast_func=float )
    # err (extract & convert to int)
    r[ 'err' ] = attr_from_result( r, 'err' )
    # nentries (extract & convert to int)
    r[ 'nentries' ] = attr_from_result( r, 'nentries' )
    # notes (string) indicate unindexed action (maybe others)
    r[ 'notes' ] = attr_from_result( r, 'notes', cast_func=str, default=None )


# @timing
def process_json_events():
    args = get_args()
    count = 0
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
        # filter on etime
        if record['etime'] < args.etime:
            continue
        # filter on action
        if args.actions and record['action'] not in args.actions:
            continue
        # filter on timestamp - find events near args.time
        if record['time'] < args.tsmin:
            continue
        if record['time'] > args.tsmax:
            continue
        # filter on client
        if args.include_clients:
            if record['client'] not in args.include_clients:
                continue
        if args.exclude_clients:
            if record['client'] in args.exclude_clients:
                continue
        # filter on notes
        if args.notes:
            note_match = False
            for n in args.notes:
                if n in record['notes']:
                    note_match = True
            if not note_match:
                continue

        # TODO - filter on err code

        # TODO - filter on nentries

        # connection = record['connection']
        # operation = record['operation']
        add_event( record )


def cleanup( r, fields_to_keep ):
    '''Remove all but user requested output fields.'''
    keys_to_delete = set(r.keys()) - set(fields_to_keep)
    for k in keys_to_delete:
        del r[k]
    # force remaining keys to hashable types
    list_types = [ 'requests', 'responses' ]
    for key in list_types:
        if key in r:
            r[key] = frozenset( r[key] )


def groupby_sum():
    args = get_args()
    f1, f2, *garbage = args.fields
    df = pd.DataFrame( get_events() )
    data = df.groupby(f1)[f2].agg(row_count='size', sum_etime='sum')
    print( data )


@timing
def print_records():
    args = get_args()
    data = pd.DataFrame( get_events() )
    data = data.reindex( columns=args.fields )
    # logging.debug( data.columns.tolist() )
    data.sort_values( by=args.fields, inplace=True, ignore_index=True )
    if args.format == 'csv':
        print( data.to_csv() )
    elif args.format == 'json':
        print( data.to_json() )
    elif args.showall:
        # these are the defaults
        display_options = [ 'display.max_rows', None, 'display.max_columns', None ]
        with pd.option_context( *display_options ):
            print( data )
    else:
        print( data )


def print_runtime():
    args = get_args()
    end_time = time.time()
    elapsed = end_time - args.start_time
    runtime = datetime.timedelta( seconds=elapsed )
    logging.info( f'Runtime: {runtime}' )


def run():
    args = get_args()
    process_json_events()
    if args.groupby_sum:
        groupby_sum()
    else:
        print_records()
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
    # raise SystemExit( 'DEBUG EXIT' )
    run()
