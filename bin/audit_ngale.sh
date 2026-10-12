#!/bin/bash

HOST=$(hostname)


check_root() {
  # If not running as root, then enable SUDO
  [[ $EUID -ne 0 ]] && SUDO=$( which sudo )
}


get_json_files() {
  local _access_log_dir
  _access_log_dir=/var/log/dirsrv/slapd-ncsa-ldap
  ${SUDO} find "${_access_log_dir}" -mindepth 1 -maxdepth 1 -type f -name 'access.2026*' \
  | sort \
  | tail -1
}


get_client_access_data() {
  local _fn
  _fn="${1}"
  ${SUDO} cat "${_fn}" \
  | grep -F 'connection from' \
  | awk '{print $9}' \
  | sort \
  | uniq -c
}


###
# MAIN
###
check_root

for fn in $( get_json_files ); do
  ACCESS_DATE=$( basename "${fn}" | cut -c 8-15 | xargs -r -I{} date -d {} '+%Y-%m-%d' )
  get_client_access_data "${fn}" \
  | while read count ip; do
      client=$(dig -x $ip +short | head -1 | sed -e 's/\.$//');
      echo "${ACCESS_DATE},${HOST},${client},${ip},,,${count}"
  done
done

#grep -F 'connection from' access.20261010-203241 | awk '{print $9}' | sort | uniq -c | while read count ip; do client=$(dig -x $ip +short); echo $count $ip $client; done
