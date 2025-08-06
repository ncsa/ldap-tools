# See also:
# https://docs.redhat.com/en/documentation/red_hat_directory_server/12/pdf/securing_red_hat_directory_server/Red_Hat_Directory_Server-12-Securing_Red_Hat_Directory_Server-en-US.pdf

. ds_lib.sh #defines vars and functions


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

import_server_cert

import_ca_cert
