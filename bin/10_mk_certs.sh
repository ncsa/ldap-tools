#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/ds_lib.sh

HOOK_DIR="${LETSENCRYPT_BASE}"/renewal-hooks
PRE_DIR="${HOOK_DIR}"/pre
PRE_HOOK="${PRE_DIR}"/99_open_firewall_port_80.sh
POST_DIR="${HOOK_DIR}"/post
POST_HOOK="${POST_DIR}"/99_close_firewall_port_80.sh
TEST=1

# Get certs

## Setup pre-hook script
setup_pre_hook() {
  echo
  echo "Setup pre-hook"
  [[ -d "${PRE_DIR}" ]] || {
    echo "making pre-hook dir"
    mkdir -p "${PRE_DIR}"
  }
  [[ -f "${PRE_HOOK}" ]] || {
    echo "pre-hook file not found, creating it"
    cat <<ENDHERE > "${PRE_HOOK}"
/usr/sbin/iptables -I INPUT -p tcp -m multiport --dports 80 -j ACCEPT
ENDHERE
  }
  [[ -x "${PRE_HOOK}" ]] || {
    echo "settin pre-hook perms"
    chmod +x "${PRE_HOOK}"
  }
  echo "OK"
}

## Setup post-hook script
setup_post_hook() {
  echo
  echo "Setup post-hook"
  [[ -d "${POST_DIR}" ]] || {
    echo "making pre-hook dir"
    mkdir -p "${POST_DIR}"
  }
  [[ -f "${POST_HOOK}" ]] || {
    echo "post-hook file not found, creating it"
    cat <<ENDHERE > "${POST_HOOK}"
/usr/sbin/iptables -D INPUT -p tcp -m multiport --dports 80 -j ACCEPT
ENDHERE
  }
  [[ -x "${POST_HOOK}" ]] || {
    echo "settin post-hook perms"
    chmod +x "${POST_HOOK}"
  }
  echo "OK"
}

## Add email to top config
set_email() {
  echo
  echo "Set email"
  /usr/bin/certbot \
    --email "${EMAIL}" \
    --no-eff-email \
    --agree-tos
  echo "OK"
}

## Test cert
test_cert() {
  TEST=1
  echo
  echo "Testing certbot ..."
  get_cert
}

get_cert() {
  local _test_opts=()
  [[ $TEST -gt 0 ]] && _test_opts=( '--dry-run' '--test-cert' )
  set -x
  /usr/bin/certbot \
    certonly \
    --standalone \
    --verbose \
    -d "${HOST}" \
    --pre-hook "${PRE_HOOK}" \
    --post-hook "${POST_HOOK}" \
    "${_test_opts[@]}" \
  ;
  set +x
}


show_certs() {
  /usr/bin/certbot certificates
}


enable_certbot_renewals() {
  systemctl start certbot-renew.timer
}

# Main

setup_pre_hook

setup_post_hook

set_email

test_cert && {
  unset TEST
  get_cert
}

show_certs

enable_certbot_renewals
