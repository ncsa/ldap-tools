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


configure_tls() {
  _dsconf \
    security set \
    --security on \
    --secure-port 636 \
    --check-hostname off
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
  cat <<ENDHERE | /usr/bin/expect -f - || die 'problem during disable_389'
  spawn ${INSTALL_DIR}/bin/dsconf security disable_plain_port
  expect "Type 'Yes I am sure' to continue: "
  send -- "Yes I am sure\n"
  expect {
    "Plaintext port disabled - please restart your instance to take effect" {
    }
    timeout {
      exit 1
    }
  }
ENDHERE
}


ldap_restart() {
  _dsctl restart
}


###
# MAIN
###

#enable_tls
configure_tls

set_nss_stuff

disable_plain_text_port

ldap_restart
