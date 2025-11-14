#!/bin/bash

# tail LDAP access log and send json lines to syslog and to json output file
# Script to be run by systemd

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

LAP="${INSTALL_DIR}"/bin/lap

"${LAP}" -tail "${DS_LOG_DIR}"/access \
| logger --tag 'ldap_access_parser' --size 4096
