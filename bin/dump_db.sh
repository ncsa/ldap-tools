#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


dump_db() {
  local _ts_start=$SECONDS
  _dsctl db2ldif --replication userRoot
  local _ts_end=$SECONDS
  local _elapsed=$( bc <<< "$_ts_end - $_ts_start" )
  echo "Database backup took: ${_elapsed} secs"

  local _ldif_out_fn=$( ls -t "${DS_LDIF_DIR}" | head -1)
  local _src="${DS_LDIF_DIR}"/"${_ldif_out_fn}"
  local _tgt=/tmp/replcheck_"${HOST}"."${_ldif_out_fn}"
  # ln -s -r "${DS_LDIF_DIR}"/"${_ldif_out_fn}" "${DS_LDIF_DIR}"/replcheck_${HOST}.ldif
  mv "${_src}" "${_tgt}"
  chmod o+r "${_tgt}"
  echo  "Bkup LDIF: '${_tgt}'"
}


purge_old() {
  rm -f /tmp/replcheck_*.ldif
}

###
# MAIN
###

continue_or_exit "DS389 will be stopped during the backup. Continue?"

purge_old

_dsctl stop

dump_db

_dsctl start

