#!/bin/bash

INSTALL_DIR=___INSTALL_DIR___
. "${INSTALL_DIR}"/lib/ds_lib.sh

DEBUG=$NO

BIN="${INSTALL_DIR}"/bin
EVENT_PARSER="${BIN}"/eventparser.py
LOG_DIR=/var/log/dirsrv
LOG_FN_BASE=ldap-access-logs.json
ELAPSED_TIMES=()
TIMESTAMPS=()


###
# MAIN
###

[[ $DEBUG -eq $YES ]] && action=echo

cat <<ENDHERE
Input lines of two-tuples in format: "elapsed timestamp"
where "elapsed" is a float
and "timestamp" uses date format %Y-%m-%d:%H:%M:%S

ENDHERE

while read -r elapsed ts ; do
  ELAPSED_TIMES+=( "${elapsed}" )
  TIMESTAMPS+=( "${ts}" )
done

for i in "${!TIMESTAMPS[@]}" ; do 
  _ts="${TIMESTAMPS[$i]}"
  _elapsed="${ELAPSED_TIMES[$i]}"
  _fn_sfx="${_ts%????}0"
  _fn_abs="${LOG_DIR}"/"${LOG_FN_BASE}"."${_fn_sfx}"

  set -x
  $action "${EVENT_PARSER}" \
    -t "${_ts}" \
    -B "${_elapsed}" \
    -f action \
    -f etime \
    --groupby_sum \
    --verbose \
    "${_fn_abs}"
  set +x

done
