#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

HOOK_DIR="${LETSENCRYPT_BASE}"/renewal-hooks
PRE_DIR="${HOOK_DIR}"/pre
PRE_HOOK="${PRE_DIR}"/01_open_firewall_port_80.sh
POST_DIR="${HOOK_DIR}"/post
POST_HOOK="${POST_DIR}"/99_close_firewall_port_80.sh
TEST=$YES

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
    echo "setting pre-hook perms"
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
    echo "setting post-hook perms"
    chmod +x "${POST_HOOK}"
  }
  echo "OK"
}

## Add email to top config
set_email() {
  echo
  echo "Set email"
  /usr/bin/certbot \
    register \
    --email "${EMAIL}" \
    --no-eff-email \
    --agree-tos
  echo "OK"
}


## Make SAN (subject alternative name) names
mk_SANs() {
  if [[ -z "${SA_NAMES}" ]] ; then
    local _round_robin_dns_names _ip_string _raw_IPs _my_IPs _sa_names
    declare -A _sa_names
    _round_robin_dns_names=(
      ldap-1.ncsa.illinois.edu
      ldap-2.ncsa.illinois.edu
      ldap-test.ncsa.illinois.edu
      ldap-auth.ncsa.illinois.edu
    )
    _ip_string=$( hostname -I | tr -d "\n" )
    readarray -d' ' -t _raw_IPs <<< "${_ip_string}"
    _my_IPs=()
    for ip in "${_raw_IPs[@]}"; do
      # ignore garbage and lines with just a newline
      [[ "${#ip}" -gt 7 ]] && _my_IPs+=( "${ip}" )
    done
    # for each round robin DNS name, get all IPs as a single string
    # if any of my local IPs are in a RR string, then add that RR name to the SAN
    # list
    for rr in "${_round_robin_dns_names[@]}"; do
      rr_IPs=( $( dig +short "$rr" ) )
      rr_IP_list=$( echo "${rr_IPs[@]}" )
      for ip in "${_my_IPs[@]}"; do
        [[ "${rr_IP_list}" == *"${ip}"* ]] && _sa_names[$rr]=1
      done
    done
    SA_NAMES=$( echo "${!_sa_names[@]}" | tr ' ' ',' )
  fi
  echo "${SA_NAMES}"
}


## Test cert
test_cert() {
  local _rc
  TEST=$YES
  echo
  echo "Testing certbot ..."
  get_cert
  _rc=$?
  TEST=$NO
  return $_rc
}


get_cert() {
  local _test_opts _domains _sans
  _test_opts=()
  [[ $TEST -eq $YES ]] && _test_opts=( '--dry-run' '--test-cert' )
  _sans=$( mk_SANs )
  [[ -n "${_sans}" ]] && _sans=",${_sans}"
  _domains="${HOST}${_sans}"
  set -x
  /usr/bin/certbot \
    certonly \
    --non-interactive \
    --keep \
    --standalone \
    --verbose \
    --cert-name "${HOST}" \
    -d "${_domains}" \
    --pre-hook "${PRE_HOOK}" \
    --post-hook "${POST_HOOK}" \
    "${_test_opts[@]}" \
    "${_certbot_extra_opts[@]}" \
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

certbot_extra_options=()
[[ "$1" == "force" ]] && certbot_extra_options+='--force-renewal'
[[ "$1" == "expand" ]] && certbot_extra_options+='--expand'

setup_pre_hook

setup_post_hook

set_email

test_cert && get_cert

show_certs

enable_certbot_renewals
