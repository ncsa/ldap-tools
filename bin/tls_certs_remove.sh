#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

JQ="${INSTALL_DIR}"/bin/jq


get_certnames() {
  [[ $DEBUG -eq $YES ]] && set -x
  _dsconf -j security certificate list \
  | jq '.[].attrs.nickname'
}


get_ca_certnames() {
  [[ $DEBUG -eq $YES ]] && set -x
  _dsconf -j security ca-certificate list \
  | jq '.[].attrs.nickname'
}


delete_cert() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _certname
  _certname="${1}"
  [[ -z "${_certname}" ]] && die 'missing certname'
  _dsconf security certificate del "${_certname}"
}


delete_ca_cert() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _ca_certname
  _ca_certname="${1}"
  [[ -z "${_ca_certname}" ]] && die 'missing CA certname'
  _dsconf security ca-certificate del "${_ca_certname}"
}


###
# MAIN
###
[[ $DEBUG -eq $YES ]] && set -x

readarray -t certnames < <( $( get_certnames ) )

readarray -t ca_certnames < <( $( get_ca_certnames) )

echo "Found host certs: ${certnames[@]}"
echo "Found CA certs: ${ca_certnames[@]}"

for cname in "${certnames[@]}"; do
  ask_yes_no "Really delete cert '${cname}'?" \
  && delete_cert "${cname}"
done

for ca in "${ca_certnames[@]}"; do
  ask_yes_no "Really delete CA cert '${ca}'?" \
  && delete_ca_cert "${ca}"
done
