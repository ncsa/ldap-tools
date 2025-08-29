import dateutil
import argparse
import fileinput
import json
import pprint
import collections
import logging


# module defined types
nested_dict = lambda: collections.defaultdict( nested_dict )

# module level variables
resources = {}

def get_args( params=None ):
    key = 'args'
    if key not in resources:
        constructor_args = {
            # 'formatter_class': argparse.ArgumentDefaultsHelpFormatter,
            # 'description': textwrap.dedent( '''\
            #     Convenient listing of all parents and children 
            #     of the "operational categories" custom field.
            #     ''')
            }
        parser = argparse.ArgumentParser( **constructor_args )
        parser.add_argument( '-d', '--debug', action='store_true' )
        parser.add_argument( '-v', '--verbose', action='store_true' )
        parser.add_argument( '-e', '--etime', type=float, default=0 )
        parser.add_argument( '-j', '--json', action='store_true' )
        # parser.add_argument( '-i', '--IP' )
        # parser.add_argument( '-t', '--time' )
        parser.add_argument( 'infiles', nargs='*', default='-' )
        args = parser.parse_args( params )
        resources[key] = args
    return resources[key]


def get_warnings():
    key = 'errs'
    if key not in resources:
        resources[key] = []
    return resources[key]


def warn( msg ):
    ''' Log a warning to the screen and,
        Also save it in an array for later retrieval of all warnings.
    '''
    key = 'errs'
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


def get_events():
    key = 'events'
    if key not in resources:
        resources[key] = nested_dict()
    return resources[key]
# events = {
#     client = {
#         connection = {
#             operation = [ records, ... ],
#         }
#     }
# }

def get_records():
    rlist = []
    for client, d1 in get_events().items():
        for conn,d2 in d1.items():
            for op,record in d2.items():
                rlist.append( record )
    return rlist


def max_etime( r ):
    etimes = [-1]
    for line in r['responses']:
        for part in line.split():
            if part.startswith( 'etime=' ):
                subpart = part[6:]
                etimes.append( float( part[6:] ) )
    return max(etimes)


def process_json_events():
    args = get_args()
    events = get_events()
    for line in fileinput.input( args.infiles ):
        #records.append( json.loads( line ) )
        record = json.loads( line )
        client = record['client']
        # ignore local requests
        if client == 'local':
            continue
        server = record['server']
        if server == client:
            continue
        # filter on etime
        if args.etime:
            etime = max_etime( record )
            if etime < args.etime:
                continue
        connection = record['connection']
        operation = record['operation']
        # TODO - filter on IP
        # TODO - find events near args.time
        events[ client ][ connection ][ operation ] = record


def print_records():
    args = get_args()
    records = get_records()
    if args.json:
        print( json.dumps( records ) )
    else:
        pprint.pprint( records )


def run():
    process_json_events()
    # pprint.pprint( get_events() )
    print_records()


if __name__ == '__main__':
    args = get_args()
    loglvl = logging.WARNING
    if args.verbose:
        loglvl = logging.INFO
    if args.debug:
        loglvl = logging.DEBUG
    logfmt = '%(levelname)s:%(funcName)s[%(lineno)d] %(message)s'
    logging.basicConfig( level=loglvl, format=logfmt )
    run()
