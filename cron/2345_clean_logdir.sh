#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

MAX_SIZE=5120 #size in MB
MAX_AGE=28 #days, files older will be deleted


too_big() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _current_size _diff_size _max_KB
  _max_KB=$( bc <<< "${MAX_SIZE} * 1024" )
  _current_size=$( du -s "${POST_LOG_DIR}"/ | head -1 | awk '{print $1}' )
  _diff_size=$( bc <<< "${_current_size} - ${_max_KB}" )
  [[ ${_diff_size} -gt 0 ]]
}


files_remain() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _num_files
  _num_files=$( ls -1 "${POST_LOG_DIR}"/ | wc -l )
  [[ ${_num_files} -gt 0 ]]
}


rm_old_files() {
  # blindly delete all files older than MAX_AGE
  [[ $DEBUG -eq $YES ]] && set -x
  find "${POST_LOG_DIR}"/ -type f -mtime +"${MAX_AGE}" -delete
}


cleanup_big_files() {
  # clean up files known to be big based on name
  [[ $DEBUG -eq $YES ]] && set -x
  local _name_globs _counter _mmin
  _name_globs=( '*.json' )
  _counter="${MAX_AGE}"
  while too_big ; do
    [[ ${_counter} -lt 0 ]] && break
    _mmin=$( bc <<< "${_counter} * 1440" )
    for glob in "${_name_globs}" ; do
      find "${POST_LOG_DIR}"/ -type f -name "${glob}" -mmin +${_mmin} -delete
    done
    _counter=$( bc <<< "${_counter} - 1" )
done
}


cleanup_anything() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _counter _mmin
  _counter=${MAX_AGE}
  while too_big && files_remain ; do
    [[ ${_counter} -lt 0 ]] && die "removed all files but size still too big"
    _mmin=$( bc <<< "${_counter} * 1440" )
    find "${POST_LOG_DIR}"/ -type f -mmin +${_mmin} -delete
    _counter=$( bc <<< "${_counter} - 1" )
  done
}


###
# MAIN
###

[[ $DEBUG -eq $YES ]] && set -x

rm_old_files

cleanup_big_files

cleanup_anything
