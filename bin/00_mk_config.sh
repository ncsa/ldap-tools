#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
SAMPLE_CONFIG="${INSTALL_DIR}"/conf/example
TMP_CONFIG="${INSTALL_DIR}"/conf/tmp
TGT_CONFIG_PATH="${INSTALL_DIR}"/conf/config
YES=0
NO=1
DEBUG=$NO
#DEBUG=$YES


ask_enum() {
  # Ask the user to choose from a custom list of choices
  # Caller should make the first option in the list the most common
  # First option is also the default, which will be chosen
  # ... if the user responds to the select-prompt with a 0 (or other non-valid
  # ... response)
  [[ $DEBUG -eq $YES ]] && set -x
  local _default _choice
  _default="$1"
  select result ; do
    if [[ "${#result}" -gt 0 ]] ; then
      _choice="$result"
    else
      _choice="$_default"
    fi
    break
  done
  echo "${_choice}"
}


ask_no_yes() {
  # Ask No or Yes
  # First option is No
  # Use this when the most common answer is no,
  # ... enables the user to respond "1" for most installs
  [[ $DEBUG -eq $YES ]] && set -x
  local rv msg ny
  rv=1
  msg="Is this ok?"
  [[ -n "$1" ]] && msg="$1"
  echo "$msg" 1>&2
  ny=$( ask_enum "No" "Yes" )
  case $ny in
    Yes) rv=0;;
    No ) rv=1;;
  esac
  return $rv
}


get_instance_name() {
  local _instance_name _prompt _default
  _default="ncsa-test-ldap"
  _prompt="What LDAP Instance name? [${_default}]"
  read -p "${_prompt}" response
  if [[ "${#response}" -gt 0 ]] ; then
    _instance_name="${response}"
  else
    _instance_name="${_default}"
  fi
  echo "${_instance_name}"
}


update_config() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _varname _value
  _varname="$1"
  _value="$2"
  sed -i -e "/^${_varname}/c ${_varname}=${_value}" "${TMP_CONFIG}"
}


###
# MAIN
###

# Quick exit if config already exists
[[ -f "${TGT_CONFIG_PATH}" ]] && {
  echo "Config file already exists ..." 1>&2
  ls -l "${TGT_CONFIG_PATH}"
  exit 0
}

# make temp config for work-in-progress edits
cp "${SAMPLE_CONFIG}" "${TMP_CONFIG}"

# set DS_INSTANCE_NAME
DS_INSTANCE_NAME=$( get_instance_name )
update_config "DS_INSTANCE_NAME" "${DS_INSTANCE_NAME}"

# set PAM_AUTH
if ask_no_yes "Enable PAM auth? [No]"; then
  update_config "PAM_AUTH" '$YES'
fi

# set DB type
echo "What DB type? [mdb]" 1>&2
db_type=$( ask_enum mdb bdb )
update_config "DS_DB_LIB" "${db_type}"

# set replication port and protocol
prompt="Use port 389 for replication? [No]"
if ask_no_yes "${prompt}" ; then
  update_config "REPL_PORT" "'389'"
  update_config "REPL_PROTOCOL" "'LDAP'"
fi

# Save finalized config
CFG_DIR="${HOME}"/.config/ldap/"${DS_INSTANCE_NAME}"
CFG_PATH="${CFG_DIR}"/config
CFG_SYMLINK_NAME="${INSTALL_DIR}"/conf/config
mkdir -p "${CFG_DIR}"
mv "${TMP_CONFIG}" "${CFG_PATH}"
ln -s "${CFG_PATH}" "${CFG_SYMLINK_NAME}"
