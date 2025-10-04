#!/bin/bash

LDAPSEARCH=/bin/ldapsearch
HOST=$( hostname -f )

"${LDAPSEARCH}" \
  -H ldaps://"${HOST}" \
  -D "cn=Directory Manager" \
  -y /root/ldap.RootDNPwd \
  -o ldif-wrap=no \
  -xLLL \
  "${@}"
