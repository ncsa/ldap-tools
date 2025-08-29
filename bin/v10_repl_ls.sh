#!/bin/bash

LDAPSEARCH=/bin/ldapsearch
HOST=$( hostname -f )

"${LDAPSEARCH}" \
  -H ldaps://"${HOST}" \
  -b "cn=mapping tree,cn=config" \
  -D "cn=Directory Manager" \
  -x \
  -y /root/ldap.RootDNPwd \
  -o ldif-wrap=no \
  objectClass=nsDS5ReplicationAgreement -LL
