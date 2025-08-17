#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


configure_memberof() {
  _dsconf plugin memberof \
    set --groupattr=uniqueMember

  _dsconf plugin memberof \
    enable

  # check with
  _dsconf plugin list | grep -i memberof
}


configure_krb_auth() {
  _dsconf plugin pam-pass-through-auth \
    enable

  # check with ?
  _dsconf plugin list | grep -i through
}


###
# MAIN
###

configure_memberof

[[ $PAM_AUTH -eq $YES ]] \
  && configure_krb_auth
