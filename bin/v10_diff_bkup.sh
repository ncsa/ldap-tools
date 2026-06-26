#!/bin/bash

YES=0
NO=1
DEBUG=$NO
# DEBUG=$YES

TS=$( date +%Y%m%dT%H%M%S )
WORK_DIR=/usr/local/crashplan/cache/ldifs
BKUP_PATH="${WORK_DIR}"/"${TS}".ldif
DIFF_PATH= # defined in diff_last_2_backups()
EMAIL_TO=aloftus@illinois.edu
EMAIL_SUBJECT="ldap bkup diff"
DB2LDIF=/sbin/db2ldif
OK_TO_SEND_MAIL=$NO


# ANSI escape codes for colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

err() {
  echo -e "${RED}✗ ERROR: $*${NC}"
}


success() {
  echo -e "${GREEN}✓ $*${NC}"
}


die() {
  err "$*"
  echo "from (${BASH_SOURCE[1]} [${BASH_LINENO[0]}] ${FUNCNAME[1]})"
  kill 0
  exit 99
}


info() {
  [[ $VERBOSE -eq $YES ]] && {
    echo -e "${RED}INFO: ${NC}$*" 1>&2
  }
}


debug() {
  [[ $DEBUG -eq $YES ]] && {
    echo -e "${RED}DEBUG: ${NC}$*" 1>&2
  }
}


mk_backup() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _err_path _err_line_count
  _err_path=$( mktemp )
  "${DB2LDIF}" -s "dc=ncsa,dc=illinois,dc=edu" -a "${BKUP_PATH}" 1>/dev/null 2>"${_err_path}"
  [[ -f "${BKUP_PATH}" ]] || die "failed to make ldif '${BKUP_PATH}'"
  _err_line_count=$( wc -l "${_err_path}" | cut -d' ' -f1 )
  if [[ ${_err_line_count} -gt 3 ]] ; then
    cat "${_err_path}"
    rm "${_err_path}"
    die 'Error while making backup'
  fi
  rm "${_err_path}"
  gzip -9 "${BKUP_PATH}"
  [[ -f "${BKUP_PATH}".gz ]] || die "failed to find ldif gzip '${BKUP_PATH}.gz'"
}


diff_last_2_backups() {
  [[ $DEBUG -eq $YES ]] && set -x
  # diff the two most recent files
  local _src_files _start_ts _end_ts
  _src_files=( $( ls -tr "${WORK_DIR}"/*.ldif.gz | tail -n 2 ) )
  _start_ts=$( basename "${_src_files[0]}" .ldif.gz )
  _end_ts=$( basename "${_src_files[1]}" .ldif.gz )
  DIFF_PATH="${_start_ts}"-"${_end_ts}".diff
  zdiff -u "${_src_files[@]}" > "${DIFF_PATH}"
  [[ -f "${DIFF_PATH}" ]] || die "Failed to make diff file '${DIFF_PATH}'"
  gzip -9 "${DIFF_PATH}"
  DIFF_PATH="${DIFF_PATH}".gz
  [[ -f "${DIFF_PATH}" ]] || die "failed to make diff gzip '${DIFF_PATH}'"
}


mail_diff() {
  [[ $DEBUG -eq $YES ]] && set -x
  [[ $OK_TO_SEND_MAIL -eq $YES ]] || return 0 #exit here if not sending mail
  local _diff_fn _diff_name
  _diff_fn=$( basename "${DIFF_PATH}" )
  _diff_name=$( echo "${_diff_fn}" | cut -d. -f1 )
  cat <<ENDHERE | mailx -a "${DIFF_PATH}" -s "${EMAIL_SUBJECT} ${_diff_name}" "${EMAIL_TO}"
file attached ${_diff_fn}
ENDHERE
}


cleanup() {
  [[ $DEBUG -eq $YES ]] && set -x
  find "${WORK_DIR}" -maxdepth 1 -type f -mtime +2
}


###
# MAIN
###

mk_backup

diff_last_2_backups

mail_diff

cleanup
