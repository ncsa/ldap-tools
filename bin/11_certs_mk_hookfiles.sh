#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

HOOK_DIR="${LETSENCRYPT_BASE}"/renewal-hooks
DEPLOY_DIR="${HOOK_DIR}"/deploy


mk_deploy_hooks() {
  pushd "${DEPLOY_DIR}"
  for f in 12_certs_install.sh 13_certs_enable.sh ; do
    ln -s "${INSTALL_DIR}"/bin/$f
  done
  popd
}


###
# Main
###

mk_deploy_hooks
