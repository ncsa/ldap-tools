#!/usr/bin/bash


die() {
  echo "$*"
  echo "from (${BASH_SOURCE[1]} [${BASH_LINENO[0]}] ${FUNCNAME[1]})"
  kill 0
  exit 99
}


validate_target() {
  [[ -z "${TGT}" ]] && die 'Missing target host'
}


assert_host() {
  local _this_host=$( hostname )
  [[ "${_this_host}" != 'eukelade' ]] && die "cant run this here"
}

set -x

###
# MAIN
###

assert_host

TGT="${1}"
shift
validate_target

USER=$( whoami )
FILTER="uid=${USER}"
ATTRS=( loginShell email cn dn )

ldapsearch \
  -H ldaps://"${TGT}".ncsa.illinois.edu:636 \
  -D "uid=${USER},ou=People,dc=ncsa,dc=illinois,dc=edu" \
  -W \
  -x \
  -b "dc=ncsa,dc=illinois,dc=edu" \
  "${FILTER}" \
  "${ATTRS[@]}" \
  | tail -7
