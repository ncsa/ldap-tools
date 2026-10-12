#!/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

JQ="${INSTALL_DIR}"/bin/jq
SUDO=
declare -A CLIENT_IPS

check_root() {
  # If not running as root, then enable SUDO
  [[ $EUID -ne 0 ]] && SUDO=$( which sudo )
}


get_json_files() {
  ${SUDO} find "${POST_LOG_DIR}" -mindepth 1 -maxdepth 1 -type f -name '*access.json' \
  | sort \
  | tail -1
}


ip2hostname() {
  # Input is a csv string, the first element of which is an IPv4
  local _csv _ip
  _csv="${1}"
  _ip=$( echo "${_csv%%,*}" | tr -d '"' )
  _ip2hostname "${_ip}"
}


_ip2hostname() {
  # helper function for ip2hostname
  # Caches ip lookups
  local _ip _key _fqdn
  _ip="${1}"
  _key="x${_ip}" #prefix prevents an empty key
  # CLIENT_IPS is a cache of IP's already looked up
  if [[ -v CLIENT_IPS["${_key}"] ]] ; then
    echo "${CLIENT_IPS[${_key}]}"
  else
    _fqdn=$( dig -x "${_ip}" +short 2>/dev/null \
    | head -1 \
    | sed -e 's/\.$//'
    )
    CLIENT_IPS["${_key}"]="$_fqdn"
    echo "$_fqdn"
  fi
}


get_client_access_data() {
  local _fn
  _fn="${1}"
  ${SUDO} cat "${_fn}" \
  | "${JQ}" -rs '
      (
        group_by([.client, .action, .authenticateddn])
        | map( [ .[0].client, .[0].action, .[0].authenticateddn, length ] )
        | .[]
      )
      | @csv
    '
}


###
# MAIN
###
check_root

for fn in $( get_json_files ); do
  ACCESS_DATE=$( basename "${fn}" | cut -c -8 | xargs -r -I{} date -d {} '+%Y-%m-%d' )
  get_client_access_data "${fn}" \
  | while read data; do
      client_host=$( ip2hostname "${data}" )
      [[ ${#client_host} -lt 1 ]] && client_host='__UNKNOWN__'
      echo "${ACCESS_DATE},${HOST},${client_host},${data}"
  done
done
