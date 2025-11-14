#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


install_ldifs() {
  install \
    -D \
    --compare \
    --verbose \
    --suffix="${TS}" \
    -t /etc/dirsrv/slapd-"${DS_INSTANCE_NAME}"/schema \
  "${INSTALL_DIR}"/files/schema/*.ldif
}


validate_schema() {
  _dsconf schema list | grep -F 'NCSA' | >/dev/null tee >(cat) >(wc -l)
}


###
# MAIN
###

install_ldifs

_dsctl restart

validate_schema
