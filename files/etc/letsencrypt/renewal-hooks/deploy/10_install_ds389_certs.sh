#!/usr/bin/bash

# NOTES
# Note 1:
#   See also:
#   https://docs.redhat.com/en/documentation/red_hat_directory_server/12/html-single/securing_red_hat_directory_server/index#proc_renewing-a-tls-certificate-using-the-command-line_assembly_renewing-a-tls-certificate
# Note 2:
#   The signing authority has multiple root level and signing certs,
#   and there is no guarantee the same one's will be used for renewal.
#   It is possible to check if installed ca-certs match the renewal ca-cert,
#   but if anything changed, have to delete all installed ca-certs and then
#   add the new chain (there is only 1 chain file that includes multiple
#   ca-certs and ds389 installs all in the chain)
#   ...
#   So easiest path is to always delete installed ca-certs and add the new one.

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

_DSCONF="${INSTALL_DIR}"/bin/dsconf
JQ="${INSTALL_DIR}"/bin/jq


# From URL above ...
# if you created the private key using an external utility,
# import the server certificate and the private key:
add_new_cert() {
  [[ $DEBUG -eq $YES ]] && set -x
  _dsctl \
    tls import-server-key-cert \
    "${HOST_CERT}" \
    "${HOST_KEY}"
}


# List installed CA certs (as json)
ls_ca_certs() {
  _dsconf -j security ca-certificate list
}


## get just the CA names, nul-separated so spaces are maintained
ls_ca_cert_names_nulsep() {
  ls_ca_certs \
  | ${JQ} --raw-output0 '.[] | select( .type == "certificate") | .attrs.nickname'
}


## Remove installed CA certs
rm_ca_certs() {
  ls_ca_cert_names_nulsep \
  | xargs -r -0 -I{} $_DSCONF security ca-certificate del '{}'
}


add_ca_certs() {
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

rm_ca_certs

add_ca_certs

conditional_restart
