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


set_krb5_keytab_perms() {
  KEYTAB=/etc/krb5.keytab
  chgrp dirsrv "${KEYTAB}"
  chmod 0640 "${KEYTAB}"
}


pamd_fixup() {
  PAMD_LDAP=/etc/pam.d/ldapserver
  [[ -f "${PAMD_LDAP}" ]] \
  && sed -e 's/no_user_check/no_ccache/' "${PAMD_LDAP}"
}


###
# MAIN
###

configure_memberof

if [[ $PAM_AUTH -eq $YES ]] ; then
  configure_krb_auth
  set_krb5_keytab_perms
  pamd_fixup
fi


# TODO - configure access logging for once per day
