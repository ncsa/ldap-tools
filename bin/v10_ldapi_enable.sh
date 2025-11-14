#!/usr/bin/bash

# configure access logging for once per day

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

declare -A SETTINGS=(
  ['nsslapd-ldapilisten']=on
  ['nsslapd-ldapiautobind']=on
)

configure_setting() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _key _val
  _key="$1"
  _val="$2"
  # must use username & passwd because ldapi not enabled yet
  cat <<ENDHERE | "${LDAPMODIFY}" -H "ldaps://${HOST}" -y "${DNPW_FN}" -x -D "cn=Directory Manager"
dn: cn=config
changetype: modify
replace: $_key
${_key}: $_val
ENDHERE

}


verify_setting() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _key _val
  _key="$1"
  _val="$2"
  grep -F "${_key}" "${DSE_LDIF_FILE}" \
  | grep -F "${_key}: ${_val}"
}


###
# MAIN
###

[[ $DEBUG -eq $YES ]] && set -x

for k in "${!SETTINGS[@]}"; do
  match=$NO
  action='?unknown action?'
  if verify_setting "$k" "${SETTINGS[$k]}" ; then
    match=$YES
    action='already set to'
  else
    configure_setting "$k" "${SETTINGS[$k]}"
    verify_setting "$k" "${SETTINGS[$k]}" && {
      match=$YES
      action='successfully set to'
    }
  fi
  if [[ $match -eq $YES ]]; then
    success "$k $action ${SETTINGS[$k]}"
  fi
done
