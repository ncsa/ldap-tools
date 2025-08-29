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
[[ -z "${consumer_hostname}" ]] && die 'missing consumer hostname'
host "${REPL_FQDN}" >/dev/null 2>&1 || die "DNS lookup failed for '${consumer_hostname}'"
shift

consumer_pwd="${1}"
[[ -z "${consumer_pwd}" ]] && die 'missing replication pwd'
shift

add_consumer

check_replication

check_replication_agreement
