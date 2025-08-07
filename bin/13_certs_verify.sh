#!/usr/bin/bash

INSTALL_DIR='__INSTALL_DIR__'
. "${INSTALL_DIR}"/ds_lib.sh


set -x

get_base() {
  _ldapsearch \
    -x \
    -s \
    base
}


get_config() {
  _ldapsearch \
    -LLx \
    -b "cn=config"
}


get_replication() {
  _ldapsearch \
    -LLx \
    -b "cn=mapping tree,cn=config"
}


###
# MAIN
###

get_base

get_config

#get_replication
