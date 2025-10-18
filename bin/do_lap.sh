#!/bin/bash

LAP=/root/ldap-tools/bin/lap
ACCESS_LOG=/var/log/dirsrv/slapd-ldap/access
JQ=/root/ldap-tools/bin/jq
FN_DATE_PFX=_unknown_
OUTFN="${FN_DATE_PFX}"_access_summary.txt
TMP=lap_output.json
#TMP=test.txt
YES=0
NO=1
DEBUG=$YES


get_access_logs() {
  [[ $DEBUG -eq $YES ]] && set -x
  ACCESS_LOG=( $( ls -rt /var/log/dirsrv/slapd-ldap/access* | grep -v rotationinfo ) )
}


process_logs() {
  [[ $DEBUG -eq $YES ]] && set -x
  >"${TMP}"
  for f in "${ACCESS_LOG[@]}"; do
    "${LAP}" "${f}" >> "${TMP}"
    ls -l "${TMP}"
  done
}


count_client_accesses() {
  "${JQ}" -n -f count_client_actions.jq <"${TMP}" \
  | tr -c '[:alnum:][:space:].' ' ' \
  | awk -f filter_client_actions.awk output \
  | sort -k1n,1 \
  | tee "${OUTFN}"
}


get_time_period() {
  ( head -1; tail -1 ) <"${TMP}" \
  | "${JQ}" -n -f duration.jq \
  | tee -a "${OUTFN}"
}


mk_fn_date_pfx() {
  # make a filename prefix using the last timestamp from LAP json output
  local _ts=$( tail -1 "${TMP}" \
    | "${JQ}" '.time[:20] | strptime("%d/%b/%Y:%H:%M:%S") | mktime'
  )
  FN_DATE_PFX=$( date -d @"${_ts}" +%Y%m%dT%H%M%S )
  OUTFN="${FN_DATE_PFX}"_access_summary.txt
}


cleanup() {
  : pass
}


#get_access_logs

#process_logs

mk_fn_date_pfx

count_client_accesses

get_time_period

cleanup
