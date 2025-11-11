#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


configure_memberof() {
  _dsconf plugin memberof \
    set --groupattr=uniqueMember

  _dsconf plugin memberof \
    enable

  if [[ "${DS_DB_LIB}" == 'bdb' ]] ; then
    cat <<ENDHERE | _ldapmodify
dn: cn=MemberOf Plugin,cn=plugins,cn=config
changetype: modify
replace: memberOfDeferredUpdate
memberOfDeferredUpdate: on
ENDHERE
  fi

  # check with
  # _dsconf plugin list | grep -i memberof
  _dsconf plugin memberof status
  _dsconf plugin memberof show
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
