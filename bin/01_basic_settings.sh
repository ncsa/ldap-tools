#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


configure_memberof() {
  _dsconf \
    plugin memberof \
    set --groupattr=uniqueMember

  _dsconf \
    plugin memberof \
    enable

  # check with
  _dsconf plugin list | grep -i memberof
}


configure_krb_auth() {
  if [[ $PAM_AUTH -eq $YES ]] ; then
    _dsconf pam-pass-through-auth enable
  fi

  # check with ?
}


###
# MAIN
###

configure_memberof

configure_krb_auth
