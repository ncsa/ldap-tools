#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

declare -A BACKEND_CONFIG_SETTINGS=(
  [lookthroughlimit]=5001 # default 5000, set -1 to disable?
)

declare -A BACKEND_SUFFIX_SETTINGS=(
  [cache-memsize]=734003200 #7GB, default is 2GB
)


set_backend_config_settings() {
  local _settings_vals=()
  for k in "${!BACKEND_CONFIG_SETTINGS[@]}"; do
    _settings_vals+=("--${k}" "${BACKEND_CONFIG_SETTINGS[$k]}")
  done
  # settings take effect immediately, no need to restart
  _dsconf \
    backend config set \
    "${_settings_vals[@]}"
}


set_backend_suffix_settings() {
  local _settings_vals=()
  for k in "${!BACKEND_SUFFIX_SETTINGS[@]}"; do
    _settings_vals+=("--${k}" "${BACKEND_SUFFIX_SETTINGS[$k]}")
  done
  # settings take effect immediately, no need to restart
  _dsconf \
    backend suffix set \
    "${_settings_vals[@]}" \
    userroot

}


validate_settings() {
  _dsconf backend config get

  _dsconf backend suffix get userroot
}



###
# MAIN
###

set_backend_config_settings

set_backend_suffix_settings

validate_settings
