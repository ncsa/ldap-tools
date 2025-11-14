#!/bin/bash

# Create json logs from ds389 access logs and save to daily files

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

[[ $DEBUG -eq $YES ]] && set -x

get_last() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _last_fn _last_base
  # look at csv files for last processed because json files may have been
  # removed due to their much larger size
  _last_fn=$( find "${POST_LOG_DIR}" -mindepth 1 -maxdepth 1 -type f -name '*.csv' | sort | tail -1 )
  [[ -z "${_last_fn}" ]] && _last_fn=$( date -d "$TODAY - 7 days" +"%Y%m%d" )
  # [[ -z "${_last_fn}" ]] && _last_fn=$( date -d "$TODAY - 21 days" +"%Y%m%d" )
  _last_base=$( basename "${_last_fn}" '.csv')
  echo "${_last_base:0:8}"
}


minutes_since() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _start
  _start="${1}"
  s_epoch=$( date -d "${_start}" +%s )
  e_epoch=$( date +%s )
  echo $( bc <<< "(${e_epoch} - ${s_epoch})/60" )
}


get_access_files() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _start _mmin
  _start="${1}"
  _mmin=$( minutes_since "${_start}" )
  find "${DS_LOG_DIR}" -mindepth 1 -maxdepth 1 -type f -name 'access.2*' -mmin -"${_mmin}" -printf "%p\n" \
  | sort
}

###
# MAIN
###

#get_last
date_of_last_csv=$( get_last )
#echo "$date_of_last_csv"

access_files=( $(get_access_files "$date_of_last_csv" ) )
#echo "${access_files[@]}"

[[ $VERBOSE -eq $YES ]] && awk_verbose="Y"
startdate=$( date -d "${date_of_last_csv} + 1 day" +"%Y%m%d" )
"${INSTALL_DIR}"/bin/ldap_access_parser "${access_files[@]}" \
| /bin/awk \
    -v logdir="${POST_LOG_DIR}" \
    -v startdate="${startdate}" \
    -v enddate="${TODAY}" \
    -v send_to_syslog="Y" \
    -v verbose="${awk_verbose}" \
    -f "${INSTALL_DIR}"/bin/json_filer.awk
