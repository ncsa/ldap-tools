# general settings
INSTALL_DIR='___INSTALL_DIR___'
YES=0
NO=1

# 389ds settings
PAM_AUTH=$NO
INSTANCE_NAME=ncsa-test-ldap
SERVER_INF="${INSTALL_DIR}"/live/"${INSTANCE_NAME}".inf
DNPW_FN="${INSTALL_DIR}"/live/dnpw
#DNPW=$( cat "${DNPW_FN}" ) now at end of file, comment remains as reminder
HOST=$( hostname -f )

# certificate related
EMAIL=ldap-admin@lists.ncsa.illinois.edu
LETSENCRYPT_BASE=/etc/letsencrypt
CERT_DIR="${LETSENCRYPT_BASE}"/live/"${HOST}"
HOST_KEY="${CERT_DIR}"/privkey.pem
HOST_CERT="${CERT_DIR}"/cert.pem
CA_CERT="${CERT_DIR}"/chain.pem
CA_NAME="LetsEncrypt CA"

# host command paths
DSCONF=/usr/sbin/dsconf
DSCTL=/usr/sbin/dsctl


_dsconf() {
  $DSCONF \
    -D "cn=Directory Manager" \
    -w "${DNPW}" \
    ldap://"${HOST}" \
    "${@}"
}


_dsctl() {
  $DSCTL "${INSTANCE_NAME}" \
    "${@}"
}


_ldapsearch() {
  /usr/bin/ldapsearch \
    -H ldaps://"${HOST}":636 \
    -D "cn=Directory Manager" \
    -w "${DNPW}" \
    "${@}"
}


dump_config() {
  _ldapsearch \
    -LLx \
    -b 'cn=config'
}


get_replication_config() {
  _ldapsearch \
    -LLx \
    -b 'cn=mapping tree,cn=config'
}


mk_passwd() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 13
}

# on first run, make passwd
[[ -f "${DNPW_FN}" ]] || {
  mk_passwd >"${DNPW_FN}"
}
DNPW=$( cat "${DNPW_FN}" )
