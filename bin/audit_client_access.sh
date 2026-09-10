#!/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

JQ="${INSTALL_DIR}"/bin/jq
SUDO=

check_root() {
  # If not running as root, then enable SUDO
  [[ $EUID -ne 0 ]] && SUDO="sudo"
}


get_json_files() {
  "${SUDO}" find "${POST_LOG_DIR}" -mindepth 1 -maxdepth 1 -type f -name '*access.json' \
  | sort \
  | tail -1
}


# not needed, but it's a nice example how to
# SORT BY MULTIPLE COLUMNS/FIELDS
#
# get_clients_by_action() {
#   local _fn
#   _fn="${1}"
#   "${JQ}" -s '
#     group_by([.server, .client, .action])
#     | map({
#         server: .[0].server,
#         client: .[0].client,
#         action: .[0].action,
#         count: length
#       })
#   ' "${_fn}"
# }


get_clients() {
  local _fn
  _fn="${1}"
  "${SUDO}" cat "${_fn}" \
  | "${JQ}" -rs '
    group_by(.client)[]
    | "\(.[0].client) \(length)"
  '
}


ip2hostname() {
  dig -x "$1" +short 2>/dev/null \
  | head -1 \
  | sed -e 's/\.$//'
}



###
# MAIN
###
check_root

for fn in $( get_json_files ); do
  ACCESS_DATE=$( basename "${fn}" | cut -c -8 | xargs -r -I{} date -d {} '+%Y-%m-%d' )
  get_clients "${fn}" \
  | while read client_ip count; do
      client_host=$( ip2hostname ${client_ip} )
      [[ ${#client_host} -lt 1 ]] && client_host='__UNKNOWN__'
      echo "${ACCESS_DATE} ${HOST} ${client_ip} ${client_host} ${count}"
  done
done
