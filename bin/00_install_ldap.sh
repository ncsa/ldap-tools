#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

install_pkgs() {

  local _repos=(
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  )
  local _pkgs=(
    389-ds-base
    certbot
  )

  if [[ "${PAM_AUTH}" -eq $YES ]] ; then
    _pkgs+=(
      pam_krb5.x86_64
    )
  fi

  #install repos
  dnf -y install "${_repos[@]}"

  #install packages
  dnf -y install "${_pkgs[@]}"

}


mk_ldap_inf() {
  [[ -f "${DS_SERVER_INF}" ]] || {
    local _dnpw="$( cat ${DNPW_FN} )"
    cat <<ENDHERE >"${DS_SERVER_INF}"
[general]
[slapd]
instance_name = ${DS_INSTANCE_NAME}
root_password = ${_dnpw}
self_sign_cert = False
db_lib = mdb
[backend-userroot]
create_suffix_entry = True
suffix = ${DS_SUFFIX}
ENDHERE
  chmod 400 "${DS_SERVER_INF}"
  }
}


mk_pam_auth() {
  [[ -f "${PAM_AUTH_FN}" ]] || {
    cat <<ENDHERE >"${PAM_AUTH_FN}"
auth        sufficient    pam_krb5.so no_user_check
account     sufficient    pam_krb5.so no_user_check
account     required     pam_nologin.so
ENDHERE
  }
}


install_ldap_server() {
  local _instance_dir=/var/lib/dirsrv/slapd-"${DS_INSTANCE_NAME}"
  [[ -d "${_instance_dir}" ]] \
  || /usr/sbin/dscreate from-file "${DS_SERVER_INF}"
}


get_status() {
  _dsctl status
}


###
# MAIN
###

mk_ldap_inf

[[ "${PAM_AUTH}" -eq $YES ]] && mk_pam_auth

install_pkgs

install_ldap_server

get_status
