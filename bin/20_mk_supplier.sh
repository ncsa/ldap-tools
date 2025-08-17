#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

"${INSTALL_DIR}"/bin/mk_replica.sh supplier
