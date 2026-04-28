#!/usr/bin/bash

# See also:
# https://docs.redhat.com/en/documentation/red_hat_directory_server/12/html-single/securing_red_hat_directory_server/index#proc_renewing-a-tls-certificate-using-the-command-line_assembly_renewing-a-tls-certificate

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

JQ="${INSTALL_DIR}"/bin/jq


# If you created the private key using an external utility,
# import the server certificate and the private key:
add_new_cert() {
  [[ $DEBUG -eq $YES ]] && set -x
  _dsctl \
    tls import-server-key-cert \
    "${HOST_CERT}" \
    "${HOST_KEY}"
}


ca_cert_exists() {
  local _rv _size
  _rv=$NO
  _size=$(_dsconf -j security ca-certificate list | jq 'length' )
  [[ $_size -gt 0 ]] && _rv=$YES
  return $_rv
}


import_ca_cert() {
  # Only if one doesn't already exist
  ca_cert_exists && return
  # Import the CA certificate to the NSS database:
  [[ $DEBUG -eq $YES ]] && set -x
  _dsconf \
    security ca-certificate add \
    --file "${CA_CERT}" \
    --name "${CA_NAME}"

  # Set the trust flags of the CA certificate:
  _dsconf \
    security ca-certificate set-trust-flags \
    "${CA_NAME}" \
    --flags "CT,,"
}


conditional_restart() {
  # only need to restart when invoked by certbot
  # if invoked by certbot, RENEWED_LINEAGE and RENEWED_DOMAINS will be present
  [[ -n "${RENEWED_DOMAINS}" ]] \
  && _dsctl restart
}


###
# MAIN
###

add_new_cert

import_ca_cert

conditional_restart
