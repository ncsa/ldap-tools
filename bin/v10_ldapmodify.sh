#!/bin/bash

HOST=$( hostname -f )
PWD_FN=/root/ldap.RootDNPwd
LDAPMODIFY=/bin/ldapmodify

die() {
  echo "ERROR: ${@}"
  exit 1
}

do_ldap_modify() {
  set -x
  "${LDAPMODIFY}" \
    -H ldaps://"${HOST}" \
    -D "cn=Directory Manager" \
    -x \
    -y "${PWD_FN}" \
    -f "${1}"
}


###
# MAIN
###

[[ $# -lt 1 ]] && die "missing ldif filename"
  
[[ -f "${1}" ]] || die "ERROR: can't find file '${1}'"

do_ldap_modify "${1}"
