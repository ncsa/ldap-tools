#!/bin/bash

TS=$( date +%Y%m%d_%H%M%S )
WORK_DIR=/usr/local/crashplan/cache/ldifs
LDIF_PATH="${WORK_DIR}"/"${TS}".ldif
DIFF_PATH="${WORK_DIR}"/"${TS}".diff
EMAIL_TO=aloftus@illinois.edu
EMAIL_SUBJECT="ldap ldif diff ${TS}"


YES=0
NO=1
DEBUG=$NO
# DEBUG=$YES

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


mk_ldif() {
  [[ $DEBUG -eq $YES ]] && set -x
  db2ldif -q -s "dc=ncsa,dc=illinois,dc=edu" -a "${LDIF_PATH}"
  [[ -f "${LDIF_PATH}" ]] || die "failed to make ldif '${LDIF_PATH}'"
  gzip -9 "${LDIF_PATH}"
  [[ -f "${LDIF_PATH}".gz ]] || die "failed to find ldif gzip '${LDIF_PATH}.gz'"
}


mk_diff() {
  [[ $DEBUG -eq $YES ]] && set -x
  # diff the two most recent files
  zdiff -u $( ls -tr "${WORK_DIR}"/*.ldif.gz | tail -n 2 ) > "${DIFF_PATH}"
  [[ -f "${DIFF_PATH}" ]] || die "Failed to make diff file '${DIFF_PATH}'"
  gzip -9 "${DIFF_PATH}"
  [[ -f "${DIFF_PATH}".gz ]] || die "failed to make diff gzip '${DIFF_PATH}.gz'"
}


mail_diff() {
  cat <<ENDHERE | mailx -a "${DIFF_PATH}".gz -s "${EMAIL_SUBJECT}" "${EMAIL_TO}"
(contents attached)
ENDHERE
}


cleanup() {
  [[ $DEBUG -eq $YES ]] && set -x
  # gzip -9 "${DIFF_PATH}"
  find "${WORK_DIR}" -maxdepth 1 -type f -mtime +2
}


###
# MAIN
###

get_prev_ldif

mk_ldif

mk_diff

mail_diff

# cleanup
