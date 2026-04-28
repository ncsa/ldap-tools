
INSTALL_DIR='___INSTALL_DIR___'

# general settings
YES=0
NO=1
# ANSI escape codes for colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color
HOST=$( hostname -f )

LDAP_TOOLS_CONFIG="${INSTALL_DIR}"/conf/config
[[ -r "${LDAP_TOOLS_CONFIG}" ]] || {
  echo "Cant read config '${LDAP_TOOLS_CONFIG}'" 1>&2
  exit 99
}
. "${LDAP_TOOLS_CONFIG}"

# 389ds settings
DS_SERVER_INF=/root/.config/ldap/"${DS_INSTANCE_NAME}"/"${DS_INSTANCE_NAME}".inf
DS_LIB_DIR=/var/lib/dirsrv/slapd-"${DS_INSTANCE_NAME}"
DS_LDIF_DIR=/var/lib/dirsrv/slapd-"${DS_INSTANCE_NAME}"/ldif
DSE_LDIF_FILE=/etc/dirsrv/slapd-"${DS_INSTANCE_NAME}"/dse.ldif
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
REPL_PW_FN=/root/.config/ldap/"${DS_INSTANCE_NAME}"/replpw
REPL_DN='cn=replication manager,cn=config'

# custom cronjob related vars
POST_LOG_DIR="${DS_LOG_DIR}"/post_processed_logs
TODAY=$( date +%Y%m%d )


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


info() {
  [[ $VERBOSE -eq $YES ]] && {
    echo -e "${RED}INFO: ${NC}$*" 1>&2
  }
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


[[ -f "${REPL_PW_FN}" ]] || {
  pw_dir="$( dirname ${REPL_PW_FN} )"
  mkdir -p "${pw_dir}"
  pwd_val=$(mk_passwd)
  printf "${pwd_val}" >"${REPL_PW_FN}" #ensure there is no newline char
  chmod 400 "${REPL_PW_FN}"
}







validate_file() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _fn="${1}"
  [[ -f "${_fn}" ]] || {
    LAST_ERR_MSG="File not found: '${_fn}'"
    return ${NO}
  }
  [[ -r "${_fn}" ]] || {
    LAST_ERR_MSG="File not readable: '${_fn}'"
    return ${NO}
  }
  [[ -s "${_fn}" ]] || {
    LAST_ERR_MSG="File is 0 size: '${_fn}'"
    return ${NO}
  }
  return ${YES}
}


validate_dir() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _dir="${1}"
  [[ -d "${_dir}" ]] || {
    LAST_ERR_MSG="Directory not found: '${_dir}'"
    return ${NO}
  }
  return ${YES}
}


json_2_outfn() {
  # given a specific json input file, replace the .json suffix with a new suffix
  [[ $DEBUG -eq $YES ]] && set -x
  local _infile _new_sfx _pfx
  _infile="${1}"
  _new_sfx="${2}"
  _pfx=$( basename "${_infile}" .json )
  echo "${POST_LOG_DIR}"/"${_pfx}""${_new_sfx}"
}


mk_outfn() {
  # dummy function so get_json_logs wont fail or do something unexpected
  # Scripts calling get_json_logs must REDEFINE this function
  # so get_json_logs wont fail
  echo "UNIMPLEMENTED_mk_outfn_DEFAULT"
}
# The most common mk_outfn looks like:
#example# mk_outfn() {
#example#   [[ $DEBUG -eq $YES ]] && set -x
#example#   local _infile
#example#   _infile="${1}"
#example#   json_2_outfn "${_infile}" '.clients.csv'
#example# }


get_json_logs() {
  # List all JSON log files that might need processing
  # Write them to the file specified by the calling script
  # *** IMPORTANT ***
  # *** scripts calling this must REDEFINE ---> mk_outfn() <---
  # *** if not redefined, script will exit
  # *** END PUBLIC SERVICE ANNOUNCEMENT
  [[ $DEBUG -eq $YES ]] && set -x
  local _outfn _sources _fn_ok _tgt_fn
  _outfn="${1}"
  [[ -z "${_outfn}" ]] && die 'missing outfn in get_json_logs'
  >"${_outfn}" # truncate output file
  _sources=( $( find -L "${POST_LOG_DIR}" \
    -mindepth 1 -maxdepth 1 -type f -regextype posix-egrep \
    -regex ".+/[0-9]{8}_access\.json" \
    )
  )
  for infile in "${_sources[@]}"; do
    # check file is valid
    validate_file "${infile}" || {
      info "skipping input file '${infile}', ${LAST_ERR_MSG}"
      continue
    }

    # skip input files with today's date in the name (they are likely still
    # being written)
    if [[ "${infile}" == *"${TODAY}"* ]] ; then
      info "skipping input file '${infile}', matches today's date"
      continue
    fi

    # check file hasn't been processed yet
    _tgt_fn=$( mk_outfn "${infile}" )
    if [[ "${_tgt_fn}" == *"mk_outfn"* ]] ; then
      die 'get_json_logs got unimplemented response from mk_outfn. Did you redefine mk_outfn?'
    fi
    if [[ -f "${_tgt_fn}" ]] ; then
      info "skipping input file '${infile}', output file '${_tgt_fn}' already exists"
      continue
    fi

    echo "${infile}" >>"${_outfn}"
  done
}
