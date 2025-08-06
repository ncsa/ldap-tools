#See also: https://wiki.ncsa.illinois.edu/display/ICI/Migration+Plan+NCSA+LDAP

. ds_lib.sh

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
  local _passwd=$( cat "${DNPW_FN}" )
  cat <<ENDHERE >"${SERVER_INF}"
[general]
[slapd]
instance_name = ${INSTANCE_NAME}
root_password = ${DNPW}
self_sign_cert = False
[backend-userroot]
create_suffix_entry = True
suffix = dc=ncsa,dc=illinois,dc=edu
ENDHERE
}

###
# MAIN
###

mk_ldap_inf

install_pkgs
