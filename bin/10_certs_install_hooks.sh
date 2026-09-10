#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

HOOK_DIR="${LETSENCRYPT_BASE}"/renewal-hooks
FILES_DIR="${INSTALL_DIR}"/files


install_certbot_renewal_hook_files() {
  local _base_len _tgt_fn _tgt_dir

  # strip off this length from the filename to get the target filename
  let "_base_len = ${#FILES_DIR}"

  # for each file in src, install it into the target directory
  find "${FILES_DIR}${HOOK_DIR}" -type f \
  | while read; do
    _tgt_fn="${REPLY:${_base_len}}"
    _tgt_dir=$( dirname "${_tgt_fn}" )
    mkdir -p "${_tgt_dir}"
    install \
      -D \
      --compare \
      --verbose \
      --suffix="${TS}" \
      --mode=0755 \
      -t "${_tgt_dir}" \
      "${REPLY}"
  done
}


assert_jq() {
  # Deploy hook depends on JQ. Ensure it's installed
  "${INSTALL_DIR}"/bin/install_jq.sh
}


# Main

install_certbot_renewal_hook_files

assert_jq
