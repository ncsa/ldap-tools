#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


dump_db() {
  _dsconf backend export -r userroot
  local _ldif_out_fn=$( ls -t "${DS_LDIF_DIR}" | head -1)
  ln -s -r "${DS_LDIF_DIR}"/"${_ldif_out_fn}" "${DS_LDIF_DIR}"/replcheck_${HOST}.ldif
}

###
# MAIN
###

_dsctl stop

dump_db

_dsctl start
