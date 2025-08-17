#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


add_consumer() {
  _dsconf \
    repl-agmt create \
    --host "${consumer_hostname}" \
    --port "${REPL_PORT}" \
    --conn-protocol="${REPL_PROTOCOL}" \
    --suffix "${DS_SUFFIX}" \
    --bind-dn 'cn=replication manager,cn=config' \
    --bind-method SIMPLE \
    --bind-passwd "${consumer_pwd}" \
    --init replication_agreement_"${consumer_hostname}"
}


check_replication() {
  _dsconf \
    replication get \
    --suffix "${DS_SUFFIX}"
}


check_replication_agreement() {
  _dsconf \
    repl-agmt get \
    --suffix "${DS_SUFFIX}" \
    replication_agreement_"${consumer_hostname}"
}


###
# MAIN
###

consumer_hostname="${1}"
consumer_pwd="${2}"

add_consumer

check_replication

check_replication_agreement
