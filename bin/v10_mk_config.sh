#!/bin/bash

set -x

DS_INSTANCE_NAME=$( systemctl \
  | awk '/dirsrv@/ {split($1, parts, /[@.]/); print parts[2]}'
)
CONF_DIR="${HOME}"/.config/ldap/"${DS_INSTANCE_NAME}"
CONF_FILE="${CONF_DIR}"/config
LDAP_TOOLS="${HOME}"/ldap-tools

# mk config dir
mkdir -p "${CONF_DIR}"

# mk config
[[ -f "${CONF_FILE}" ]] \
|| cat <<ENDHERE >"${CONF_FILE}"
YES=0   #no touchee
NO=1    #no touchee
PAM_AUTH=\$NO
DS_DB_LIB=bdb
DS_INSTANCE_NAME=${DS_INSTANCE_NAME}
DS_SUFFIX='dc=ncsa,dc=illinois,dc=edu'
REPL_PORT='636'
REPL_PROTOCOL='LDAPS'
EMAIL=ldap-admin@lists.ncsa.illinois.edu
VERBOSE=\$YES
DEBUG=\$YES
NOOP=\$NO
ENDHERE

# mk ldap-tools symlink
pushd "${LDAP_TOOLS}"/conf
ln -s -f -r "${CONF_FILE}"
popd

# copy existing DN passwd
old_dnpw_file="${HOME}"/ldap.RootDNPwd
new_dnpw_file="${CONF_DIR}"/dnpw
if [[ -f "${old_dnpw_file}" ]] ; then
  cp -n "${old_dnpw_file}" "${new_dnpw_file}"
  perl -pi -e 'chomp if eof' "${new_dnpw_file}"
fi

# copy an existing replpw
old_replpw_file="${HOME}"/ldap.ReplicaBindPwd
new_replpw_file="${CONF_DIR}"/replpw
if [[ ! -f "${new_replpw_file}" ]] ; then
  # new replpw file doesn't exist yet, try to create it
  if [[ -f "${old_replpw_file}" ]] ; then
    # found local repl pw file, copy it
    cp -n "${old_replpw_file}" "${new_replpw_file}"/replpw
  elif [[ -f /root/ReplicationManager.ldif ]] ; then
    # found local replication config, extract passwd from it
    >"${new_replpw_file}" \
    awk '/userPassword:/ {print $2}' /root/ReplicationManager.ldif
  fi
fi
