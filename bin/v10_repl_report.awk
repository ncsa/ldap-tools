#!/bin/awk -f

BEGIN {
  hosts_found=0
  unset_vars()
}


function unset_vars() {
DN ="?"
HOST = "?"
REPLICA_ID = "?"
ENABLED = "?"
LAST_UPDATE_STATUS = "?"
LAST_INIT_STATUS = "?"
}

function print_replica() {
  printf "%s\n", DN
  # printf "%20s %10s %7s %18s %16s\n", "HOST", "REPLICA_ID", "ENABLED", "LAST_UPDATE_STATUS", "LAST_INIT_STATUS"
  # printf "%20s %10s %7s %18s %16s\n", HOST, REPLICA_ID, ENABLED, LAST_UPDATE_STATUS, LAST_INIT_STATUS
  printf "%40s %10s %7s %18s %16s\n", "FQDN", "REPLICA_ID", "ENABLED", "LAST_UPDATE_STATUS", "LAST_INIT_STATUS"
  printf "%40s %10s %7s %18s %16s\n", FQDN, REPLICA_ID, ENABLED, LAST_UPDATE_STATUS, LAST_INIT_STATUS
  if ( LAST_UPDATE_STATUS > 0 ) {
    print LAST_UPDATE_MSG
  }
  if ( LAST_INIT_STATUS > 0 ) {
    print LAST_INIT_MSG
  }
  printf "\n"
  unset_vars()
}

function remove_edges(str) {
  if (length(str) <= 2)
    return ""  # Return empty string if too short
  return substr(str, 2, length(str) - 2)
}

/^dn: / {
  if (hosts_found > 0) {
    print_replica()
  }
  DN = $0
  hosts_found++
}

/^nsDS5ReplicaHost: / {
  FQDN=$2
  split(FQDN, parts, ".")
  HOST=parts[1]
  # print
}

/^nsds5ReplicaEnabled: / {
  ENABLED=$2;
}

/^nsds5replicaLastUpdateStatus: / {
  # print
  LAST_UPDATE_STATUS = remove_edges($3)
  if (LAST_UPDATE_STATUS != "0") {
      LAST_UPDATE_MSG = $0
  }
}

/^nsds5replicaLastInitStatus: / {
  # print
  LAST_INIT_STATUS = remove_edges($3)
  if (LAST_INIT_STATUS != "0") {
    LAST_INIT_MSG = $0
  }
}

/^nsruvReplicaLastModified: / {
  # print
  rv = index($0, HOST)
  if ( rv > 0 ) {
    REPLICA_ID = $3
  }
}


END {
  print_replica()
}

# dn: cn=provtestra,cn=replica,cn=dc\3Dncsa\2Cdc\3Dillinois\2Cdc\3Dedu,cn=mapping tree,cn=config
# objectClass: top
# objectClass: nsds5replicationagreement
# cn: provtestra
# nsDS5ReplicaHost: ldap-provider-test.ncsa.illinois.edu
# nsDS5ReplicaPort: 636
# nsDS5ReplicaBindDN: cn=replication manager,cn=config
# nsDS5ReplicaTransportInfo: SSL
# nsDS5ReplicaBindMethod: SIMPLE
# nsDS5ReplicaRoot: dc=ncsa,dc=illinois,dc=edu
# description: agreement between ldap-master and ldap-provider-test
# nsDS5ReplicaCredentials: {AES-TUhNR0NTcUdTSWIzRFFFRkRUQm1NRVVHQ1NxR1NJYjNEUUVGRERBNEJDUXhObU13T0dNM01TMWxZbUkwTXpVdw0KTVMxaFpESmpaR0ZtTlMwMVkyWmtaVEU1WWdBQ0FRSUNBU0F3Q2dZSUtvWklodmNOQWdjd0hRWUpZSVpJQVdVRA0KQkFFcUJCRDdLMWVUeEVCMm5laWhzVUtuNUFWZQ==}ipInqZZw5drKLTe3XqTDFg==
# nsds50ruv: {replicageneration} 6702f081000000070000
# nsds50ruv: {replica 1 ldap://ldap-provider-test.ncsa.illinois.edu:389} 6702f268000100010000 68c44628000000010000
# nsds50ruv: {replica 7 ldap://ldap-master.ncsa.illinois.edu:389} 67072899000000070000 68c44747000000070000
# nsruvReplicaLastModified: {replica 1 ldap://ldap-provider-test.ncsa.illinois.edu:389} 00000000
# nsruvReplicaLastModified: {replica 7 ldap://ldap-master.ncsa.illinois.edu:389} 00000000
# nsds5replicareapactive: 0
# nsds5replicaLastUpdateStart: 19700101000000Z
# nsds5replicaLastUpdateEnd: 19700101000000Z
# nsds5replicaChangesSentSinceStartup:
# nsds5replicaLastUpdateStatus: Error (19) Replication error acquiring replica: Replica has different database generation ID, remote replica may need to be initialized (RUV error)
# nsds5replicaUpdateInProgress: FALSE
# nsds5replicaLastInitStart: 19700101000000Z
# nsds5replicaLastInitEnd: 19700101000000Z
