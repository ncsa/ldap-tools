#!/bin/bash

PRG=$( basename "$0" )
LDAP_SERVICE_NAME=dirsrv@ldap.service
DB2LDIF=/sbin/db2ldif
LDAP_SUFFIX="dc=ncsa,dc=illinois,dc=edu"
LDIF_DIR=/var/lib/dirsrv/slapd-ldap/ldif
HOST=$( hostname )


die() {
  echo "ERROR: ${@}"
  exit 1
}


purge_old() {
  rm -f /tmp/replcheck_*.ldif
}


ldap_stop() {
  systemctl stop "${LDAP_SERVICE_NAME}"
}

ldap_start() {
  systemctl start "${LDAP_SERVICE_NAME}"
}

dump_db() {
  local _start=$SECONDS
  "${DB2LDIF}" -s "${LDAP_SUFFIX}" 
  local _end=$SECONDS
  local _elapsed=$( bc <<< "$_end - $_start" )
  echo "DB backup took: $_elapsed secs"

  local _ldif_out_fn=$( ls -t "${LDIF_DIR}" | head -1)
  local _src="${LDIF_DIR}"/"${_ldif_out_fn}"
  local _tgt=/tmp/replcheck."${_ldif_out_fn}"
  mv "${_src}" "${_tgt}"
  chmod o+r "${_tgt}"
  echo "Bkup LDIF file: '${_tgt}'"

  echo -n 'Entries in DB: '
  grep '^dn: ' "${_tgt}" | wc -l
}


###
# MAIN
###

purge_old

# ldap_stop

dump_db

# ldap_start
