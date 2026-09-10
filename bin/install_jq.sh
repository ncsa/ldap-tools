#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

set -x


install_jq() {
  local _url _outfile
  _url=https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-linux-amd64
  _outfile="${INSTALL_DIR}"/bin/jq
  if [[ ! -f "${_outfile}" ]] ; then
    curl -L -o "${_outfile}" "${_url}"
    chmod +x "${_outfile}"
  fi
}

###
# MAIN
###

install_jq
