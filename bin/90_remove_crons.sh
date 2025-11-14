#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


set -x


delete_cron_entries() {
  ( crontab -l | sed '/installed by ldap-tools/,+2d' ) | crontab -
}

###
# MAIN
###

delete_cron_entries
