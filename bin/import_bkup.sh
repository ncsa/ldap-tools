#!/usr/bin/bash

INSTALL_DIR='/root/ldap-tools'
. "${INSTALL_DIR}"/lib/ds_lib.sh

SLAPD_DIR=/var/lib/dirsrv/slapd-"${DS_INSTANCE_NAME}"/ldif
IMPORT_SRC=
ERROR_LOG=/var/log/dirsrv/slapd-"${DS_INSTANCE_NAME}"/errors


validate_source() {
  [[ -z "${SRC}" ]] && die 'Missing input file'
  [[ -f "${SRC}" ]] || die "Not a file or no access: '${SRC}'"
}


prep_import() {
  local _src_fn=$( basename "${SRC}" )
  IMPORT_SRC="${SLAPD_DIR}"/"${_src_fn}"
  cp "${SRC}" "${IMPORT_SRC}"
  chown dirsrv:dirsrv "${IMPORT_SRC}"
  chmod 0400 "${IMPORT_SRC}"
  ls -l "${IMPORT_SRC}"
  stat "${IMPORT_SRC}"
}


import_backup() {
  _dsconf backend import userRoot "${IMPORT_SRC}"
}


check_logs() {
  tail -100 "${ERROR_LOG}" | grep -F " - ERR - "
  tail -100 "${ERROR_LOG}" | grep -F "import userroot"
}


validate_entries() {
  _ldapsearch -b "${DS_SUFFIX}" -s sub -x \
  | tail -7
}

set -x

###
# MAIN
###
SRC="${1}"
shift
validate_source

prep_import

import_backup

check_logs

validate_entries
