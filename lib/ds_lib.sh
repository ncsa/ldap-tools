# general settings
INSTALL_DIR='___INSTALL_DIR___'
YES=0
NO=1
VERBOSE=$YES
DEBUG=$YES
# ANSI escape codes for colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# 389ds settings
PAM_AUTH=$NO
PAM_AUTH_FN='/etc/pam.d/ldapserver'
DS_INSTANCE_NAME=ncsa-test-ldap
DS_SERVER_INF="${INSTALL_DIR}"/live/"${DS_INSTANCE_NAME}".inf
DS_SUFFIX='dc=ncsa,dc=illinois,dc=edu'
DNPW_FN="${INSTALL_DIR}"/live/dnpw
DNPW= #actual definition at end of file
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

# replication settings
REPL_PW_FN="${INSTALL_DIR}"/live/replpw
#REPL_PW= #actual definition at end of file
REPL_PORT='389'
REPL_PROTOCOL='LDAP'


err() {
  echo -e "${RED}✗ ERROR: $*${NC}" #| tee /dev/stderr
}

 
success() {
  echo -e "${GREEN}✓ $*${NC}" #| tee /dev/stderr
}
 
 
die() {
  err "$*"
  echo "from (${BASH_SOURCE[1]} [${BASH_LINENO[0]}] ${FUNCNAME[1]})"
  kill 0
  exit 99
}


_dsconf() {
  $DSCONF \
    -D "cn=Directory Manager" \
    -w "${DNPW}" \
    ldap://"${HOST}" \
    "${@}"
}


_dsctl() {
  $DSCTL "${DS_INSTANCE_NAME}" \
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
  tr -dc A-Za-z0-9 </dev/urandom | head -c 50
}

# on first run, make passwds
[[ -f "${DNPW_FN}" ]] || {
  mk_passwd >"${DNPW_FN}"
}
DNPW=$( cat "${DNPW_FN}" )


[[ -f "${REPL_PW_FN}" ]] || {
  mk_passwd >"${REPL_PW_FN}"
}
REPL_PW=$( cat "${REPL_PW_FN}" )
