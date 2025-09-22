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


ldap_stop() {
  systemctl stop "${LDAP_SERVICE_NAME}"
}

ldap_start() {
  systemctl start "${LDAP_SERVICE_NAME}"
}

dump_db() {
  "${DB2LDIF}" -r -s "${LDAP_SUFFIX}" 
  local _ldif_out_fn=$( ls -t "${LDIF_DIR}" | head -1)
  local _src="${LDIF_DIR}"/"${_ldif_out_fn}"
  local _tgt=/tmp/replcheck_"${HOST}"."${_ldif_out_fn}"
  # ln -s -r "${LDIF_DIR}"/"${_ldif_out_fn}" "${LDIF_DIR}"/replcheck_${HOST}.ldif
  mv "${_src}" "${_tgt}"
  chmod o+r "${_tgt}"
}



###
# MAIN
###

ldap_stop

dump_db

ldap_start
