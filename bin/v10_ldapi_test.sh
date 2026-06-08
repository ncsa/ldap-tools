#!/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

set -x

"${LDAPSEARCH}" \
  -H "${LDAPI}" \
  -Y EXTERNAL \
  -o ldif-wrap=no \
  -LLL \
  -b "${DS_SUFFIX}" \
  "${@}"
