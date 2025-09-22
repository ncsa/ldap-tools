#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


dump_db() {
  _dsctl db2ldif --replication userRoot
  local _ldif_out_fn=$( ls -t "${DS_LDIF_DIR}" | head -1)
  local _src="${DS_LDIF_DIR}"/"${_ldif_out_fn}"
  local _tgt=/tmp/replcheck_"${HOST}"."${_ldif_out_fn}"
  # ln -s -r "${DS_LDIF_DIR}"/"${_ldif_out_fn}" "${DS_LDIF_DIR}"/replcheck_${HOST}.ldif
  mv "${_src}" "${_tgt}"
  chmod o+r "${_tgt}"
}

###
# MAIN
###

continue_or_exit "DS389 will be stopped during the backup. Continue?"

_dsctl stop

ts_start=$SECONDS
dump_db
ts_end=$SECONDS
elapsed=$( bc <<< "$ts_end - $ts_start" )
echo "Database backup took: ${elapsed} secs"

_dsctl start

