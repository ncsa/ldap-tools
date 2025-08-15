#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

# If you created the private key using an external utility,
# import the server certificate and the private key:
import_server_cert() {
  set -x
  _dsctl \
    tls import-server-key-cert "${HOST_CERT}" "${HOST_KEY}"
}


import_ca_cert() {
  #  Import the CA certificate to the NSS database:
  set -x
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


###
# MAIN
###

import_server_cert

import_ca_cert
