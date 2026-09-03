#!/usr/bin/bash

# Test ldap-auth on a specific server.
# The ldap-auth servers are restricted so have to test from a REMOTE_HOST that
# is allowed to connect.
# Requires: ControlMaster connection multiplexing enabled so that
#           ssh connections are non-interactive after the first connection.

REMOTE_HOST=isf-ldap-01
REMOTE_SCRIPT_NAME=test_ldap_auth.sh
AUTH_HOSTS=(
  isf-ldapauth-01
)
USER=$( whoami )
FILTER="uid=${USER}"
ATTRS=( loginShell email cn dn )


die() {
  echo "$*"
  echo "from (${BASH_SOURCE[1]} [${BASH_LINENO[0]}] ${FUNCNAME[1]})"
  kill 0
  exit 99
}


mk_remote_script() {
  USER=$( whoami )
  FILTER="uid=${USER}"
  ATTRS=( loginShell email cn dn )
  cat <<ENDHERE | ssh "${REMOTE_HOST}" "cat >${REMOTE_SCRIPT_NAME}"
  ldapsearch \
    -H ldaps://"${TGT}".ncsa.illinois.edu:636 \
    -D "uid=${USER},ou=People,dc=ncsa,dc=illinois,dc=edu" \
    -W \
    -x \
    -b "dc=ncsa,dc=illinois,dc=edu" \
    "${FILTER}" \
    "${ATTRS[@]}" \
    | tail -4
ENDHERE
  # ssh "${REMOTE_HOST}" "ls -l test_ldap_auth.sh; cat ${REMOTE_SCRIPT_NAME}"
}


test_remote_host_connection() {
  # ensure we can ssh there
  # also create a control master connection if none already
  ssh "${REMOTE_HOST}" "hostname"
}


run_remote_test() {
  ssh "${REMOTE_HOST}" "bash ${REMOTE_SCRIPT_NAME}"
}


cleanup() {
  ssh "${REMOTE_HOST}" "rm -f ${REMOTE_SCRIPT_NAME}"
}

###
# MAIN
###

# allow a host to be passed in from cmdline
[[ -n "${1}" ]] && AUTH_HOSTS=( "${1}" )

test_remote_host_connection

for TGT in "${AUTH_HOSTS[@]}"; do
  echo "Testing auth host '${TGT}'"
  mk_remote_script
  run_remote_test
  cleanup
done
