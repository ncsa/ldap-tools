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
BASE=$( readlink -e $( dirname "$0" ) )


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


install_subdirs() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _dirs=( bin files live lib lap )
  local _base_len
  let "_base_len = ${#BASE} + 1"

  for dir in "${_dirs[@]}"; do

    # make target dirs
    for tgt in $( find "${BASE}"/"${dir}" -type d ); do
      local _subd="${tgt:${_base_len}}"
      install -d "${INSTALL_DIR}"/"${_subd}"
    done

    # install each file
    for file in $( find "${BASE}"/"${dir}" -type f ); do
      local _file=$( basename "${file}" )
      local _dir=$(dirname "${file}" )
      local _subd="${_dir:${_base_len}}"
      install \
        -D \
        --compare \
        --verbose \
        --suffix="${TS}" \
        -t "${INSTALL_DIR}"/"${_subd}" \
        "${file}"
    done

  done
}


mk_symlinks() {
  [[ $DEBUG -eq $YES ]] && set -x
  declare -A _links=(
    [stop]=serverctl
    [start]=serverctl
    [restart]=serverctl
    [status]=serverctl
    [dsconf]=dsc
    [dsctl]=dsc
    [ldapsearch]=dsc
    [ldapmodify]=dsc
  )

  for k in "${!_links[@]}"; do
    src="${INSTALL_DIR}"/bin/"${_links[$k]}"
    tgt="${INSTALL_DIR}"/bin/"${k}"
    [[ -e "${tgt}" ]] \
    || ln -sr "${src}" "${tgt}"
  done
}


[[ $DEBUG -eq $YES ]] && set -x

set_install_dir

install_subdirs

mk_symlinks
