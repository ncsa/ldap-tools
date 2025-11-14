#!/usr/bin/bash

# move dirsrv logs out of /var
# for when /var is a separate mountpoint and too small for daily access logs

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

LOG_BASE_OLD=/var/log/dirsrv
LOG_BASE_NEW=/srv/log/dirsrv
SVC_NAME=
[[ ${NOOP} -eq $YES ]] && ACTION=echo

get_svc_name() {
  SVC_NAME=$( systemctl | awk '$1 ~ /dirsrv@/ {print $1}' )
  [[ -z "${SVC_NAME}" ]] && die 'failed to get SVC_NAME'
}


stop_service() {
  $ACTION systemctl stop "${SVC_NAME}" || die 'failed to stop service'
}


start_service() {
  $ACTION systemctl start "${SVC_NAME}" || die 'failed to start service'
}


fixup_logdir() {
  local _new_parent
  _new_parent=$( dirname "${LOG_BASE_NEW}" )
  # make new parent dir
  mkdir -p "${_new_parent}"
  [[ -d "${_new_parent}" ]] || die "failed to make new log basedir '${_new_parent}'"
  # move old -> new
  $ACTION mv "${LOG_BASE_OLD}" "${_new_parent}" || die 'failed moving old dir'
  # symlink old -> new
  $ACTION ln -s "${LOG_BASE_NEW}" "${LOG_BASE_OLD}" || die 'error making symlink'
  [[ -L "${LOG_BASE_OLD}" ]] || die "symlink verify failed for '${LOG_BASE_OLD}'"
}




###
# MAIN
###

[[ $DEBUG -eq $YES ]] && set -x

get_svc_name
echo "Got SVC_NAME as '${SVC_NAME}'"
continue_or_exit

started_elapsed=$SECONDS

stop_service

fixup_logdir

start_service

end_elapsed=$SECONDS

runtime=$( bc <<< "$end_elapsed - $started_elapsed" )

echo "Completed in $runtime seconds."
