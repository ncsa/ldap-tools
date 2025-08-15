#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


set -x

get_base() {
  _ldapsearch \
    -x \
    -s \
    base
}


get_cert() {
  echo \
  | openssl s_client \
      -servername "${HOST}" \
      -connect "${HOST}":636 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates

}


###
# MAIN
###

get_base

get_cert
