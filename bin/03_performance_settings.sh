#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

declare -A SETTINGS=(
  [lookthroughlimit]=5001 # default 5000, set -1 to disable?
  [locks]=50000 # default=10000
)



do_configure() {
  local _settings_vals=()
  for k in "${!SETTINGS[@]}"; do 
    _settings_vals+=("--${k}" "${SETTINGS[$k]}")
  done
  # settings take effect immediately, no need to restart
  _dsconf \
    backend config set \
    "${_settings_vals[@]}"
}


validate_settings() {
  for k in "${!SETTINGS[@]}"; do
    _dsconf \
      backend config get \
    | grep -F "${k}"
  done
}



###
# MAIN
###

do_configure

validate_settings
