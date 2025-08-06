# See also:
# https://docs.redhat.com/en/documentation/red_hat_directory_server/12/pdf/securing_red_hat_directory_server/Red_Hat_Directory_Server-12-Securing_Red_Hat_Directory_Server-en-US.pdf

# INSTANCE_NAME=ncsa-test-ldap
# HOST=$( hostname -f )
# NICKNAME='Server-Cert'

. ds_lib.sh


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
    --tlsallow-rsa-certificates on \
    --nss-token "internal (software)" \
    --nss-cert-name "${NICKNAME}"
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
