
INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/conf/config

# general settings
YES=0
NO=1
# ANSI escape codes for colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color
HOST=$( hostname -f )

# 389ds settings
DS_SERVER_INF=/root/.config/ldap/"${DS_INSTANCE_NAME}"/"${DS_INSTANCE_NAME}".inf
DS_LIB_DIR=/var/lib/dirsrv/slapd-"${DS_INSTANCE_NAME}"
DS_LDIF_DIR=/var/lib/dirsrv/slapd-"${DS_INSTANCE_NAME}"/ldif
DNPW_FN=/root/.config/ldap/"${DS_INSTANCE_NAME}"/dnpw
LDAPI="ldapi://%2frun%2fslapd-${DS_INSTANCE_NAME}".socket
PAM_AUTH_FN='/etc/pam.d/ldapserver'

# 389ds log parsing & monitoring
DS_LOG_DIR=/var/log/dirsrv/slapd-"${DS_INSTANCE_NAME}"
DS_VENV="${INSTALL_DIR}"/.venv
DS_PY3="${DS_VENV}"/bin/python3

# certificate related
LETSENCRYPT_BASE=/etc/letsencrypt
CERT_DIR="${LETSENCRYPT_BASE}"/live/"${HOST}"
HOST_KEY="${CERT_DIR}"/privkey.pem
HOST_CERT="${CERT_DIR}"/cert.pem
CA_CERT="${CERT_DIR}"/chain.pem
CA_NAME="LetsEncrypt CA"

# host command paths
DSCONF=/usr/sbin/dsconf
DSCTL=/usr/sbin/dsctl
LDAPSEARCH=/usr/bin/ldapsearch
LDAPMODIFY=/usr/bin/ldapmodify


# replication settings
REPLPW_FN=/root/.config/ldap/"${DS_INSTANCE_NAME}"/replpw
REPL_DN='cn=replication manager,cn=config'


continue_or_exit() {
    local msg="Continue?"
    [[ -n "$1" ]] && msg="$1"
    echo "$msg"
    select yn in "Yes" "No"; do
        case $yn in
            Yes) return 0;;
            No ) exit 1;;
        esac
    done
}


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
    "${DS_INSTANCE_NAME}" \
    "${@}"
}


_dsctl() {
  $DSCTL \
    "${DS_INSTANCE_NAME}" \
    "${@}"
}


_ldapsearch() {
  $LDAPSEARCH \
    -H "${LDAPI}" \
    -Y EXTERNAL \
    -LLL \
    "${@}"
}


_ldapmodify() {
  # reads ldif from stdin, pipe or redirect to this function
  $LDAPMODIFY \
    -H "${LDAPI}" \
    -Y EXTERNAL
}


mk_passwd() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 50
}

# on first run, make passwds
[[ -f "${DNPW_FN}" ]] || {
  pw_dir="$( dirname ${DNPW_FN} )"
  mkdir -p "${pw_dir}"
  pwd_val=$(mk_passwd)
  printf "${pwd_val}" >"${DNPW_FN}" #ensure there is no newline char
  chmod 400 "${DNPW_FN}"
}


[[ -f "${REPLPW_FN}" ]] || {
  pw_dir="$( dirname ${REPLPW_FN} )"
  mkdir -p "${pw_dir}"
  pwd_val=$(mk_passwd)
  printf "${pwd_val}" >"${REPLPW_FN}" #ensure there is no newline char
  chmod 400 "${REPLPW_FN}"
}
