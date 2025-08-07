#!/bin/bash

YES=0 #no touchee
NO=1  #no touchee


# ###
# User might want to change these, though should use environment vars
# ###
INSTALL_DIR="${LDAPTOOLS_INSTALL_DIR:-$HOME/ldap-tools}"
DEBUG=$YES
VERBOSE=$YES
# ###
# END OF USER CONFIGURABLE SECTION
# ###


TS=$( date +%Y-%m-%d_%H%M%S )
BASE=$( dirname "$0" )


log() {
  [[ $VERBOSE -eq $YES ]] || return 0
  echo "INFO $*" >&2
}


debug() {
  [[ $DEBUG -eq $YES ]] || return 0
  echo "DEBUG (${BASH_SOURCE[1]} [${BASH_LINENO[0]}] ${FUNCNAME[1]}) $*"
}


set_install_dir() {
  [[ $DEBUG -eq $YES ]] && set -x
  # Update any files that need INSTALL_DIR
  local _pattern='___INSTALL_DIR___'
  local _replacement="$INSTALL_DIR"
  grep -r --files-with-matches -F "$_pattern" "${BASE}" \
  | while read; do
      sed -i -e "s?$_pattern?$_replacement?" "$REPLY"
    done
}


install_files() {
  install \
    -d "${INSTALL_DIR}" \
    -D \
    --compare \
    --verbose \
    --suffix="${TS}" \
    "${BASE}"/bin/*.sh
}


[[ $DEBUG -eq $YES ]] && set -x

set_install_dir

install_files
