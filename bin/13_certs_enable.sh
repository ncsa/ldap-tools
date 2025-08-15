#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


enable_tls() {
  # enable TLS and set the LDAPS port
  set -x
  _dsconf \
    config replace \
    nsslapd-securePort=636 \
    nsslapd-security=on
}

# Enable the RSA cipher family
# set the NSS database security device
# and the server certificate name
set_nss_stuff() {
  set -x
  _dsconf \
    security rsa set \
    --tls-allow-rsa-certificates on \
    --nss-token "internal (software)" \
    --nss-cert-name 'Server-Cert'
}

# Disable plain text LDAP port
disable_plain_text_port() {
  _dsconf \
    security disable_plain_port
    
}


ldap_restart() {
  _dsctl restart
}


###
# MAIN
###

enable_tls

set_nss_stuff

# disable_plain_text_port

ldap_restart
