#!/usr/bin/bash

# configure access logging for once per day

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

declare -A SETTINGS=(
  ['nsslapd-accesslog-maxlogsperdir']=102
  ['nsslapd-accesslog-maxlogsize']=100
  ['nsslapd-accesslog-logmaxdiskspace']=10240
  ['nsslapd-accesslog-logrotationtime']=1
  ['nsslapd-accesslog-logrotationtimeunit']=day
  ['nsslapd-accesslog-logrotationsync-enabled']=on
  ['nsslapd-accesslog-logrotationsynchour']=0
  ['nsslapd-accesslog-logrotationsyncmin']=0
)

configure_setting() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _key _val
  _key="$1"
  _val="$2"
  cat <<ENDHERE | _ldapmodify
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
    info "attempting change '$k' -> '${SETTINGS[$k]}'"
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
