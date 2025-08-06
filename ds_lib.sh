# See also:
# https://docs.redhat.com/en/documentation/red_hat_directory_server/12/pdf/securing_red_hat_directory_server/Red_Hat_Directory_Server-12-Securing_Red_Hat_Directory_Server-en-US.pdf

YES=0
NO=1
PAM_AUTH=$NO
INSTANCE_NAME=ncsa-test-ldap

BASE=/root/ldap
EMAIL=ldap-admin@lists.ncsa.illinois.edu

SERVER_INF="${BASE}"/"${INSTANCE_NAME}".inf
DNPW_FN="${BASE}"/dnpw
#DNPW=$( cat "${DNPW_FN}" ) now at end of file, comment remains as reminder
HOST=$( hostname -f )
LETSENCRYPT_BASE=/etc/letsencrypt
CERT_DIR="${LETSENCRYPT_BASE}"/live/"${HOST}"
HOST_KEY="${CERT_DIR}"/privkey.pem
HOST_CERT="${CERT_DIR}"/cert.pem
CA_CERT="${CERT_DIR}"/chain.pem
CA_NAME="LetsEncrypt CA"
NICKNAME='Server-Cert'
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


mk_passwd() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 13
}

# on first run, make passwd
[[ -f "${DNPW_FN}" ]] || {
  mk_passwd >"${DNPW_FN}"
}
DNPW=$( cat "${DNPW_FN}" )
