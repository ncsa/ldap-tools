#!/bin/bash

PRG=$( basename "$0" )
FQDN=$( hostname -f )
HOST=$( echo "${FQDN}" | awk -F '.' '{print $1}' )
PASSWD_FN=/root/ldap.RootDNPwd
LDAPMODIFY=/bin/ldapmodify

YES=0
NO=1
REPL_FQDN_IS_VALID=${NO}
REPL_PASSWD_IS_VALID=${NO}
REPL_CN_IS_VALID=${NO}
REPL_PORT_IS_VALID=${NO}
LAST_ERR_MSG='?'


die() {
  echo "ERROR: ${@}"
  exit 1
}


do_ldap_modify() {
  set -x
 "${LDAPMODIFY}" \
   -H ldaps://"${FQDN}" \
   -D "cn=Directory Manager" \
   -x \
   -y "${PASSWD_FN}"
}


mk_cn_from_host() {
  REPL_HOST=$( echo "${REPL_FQDN}" | awk -F '.' '{print $1}' )
  REPL_CN="ra_${REPL_HOST}"
}


mk_dn() {
  REPL_DN="cn=${REPL_CN},cn=replica,cn=\"dc=ncsa,dc=illinois,dc=edu\",cn=mapping tree,cn=config"
}


validate_fqdn() {
  if [[ ${REPL_FQDN_IS_VALID} -eq ${NO} ]] ; then
    # All must pass for FQDN to be valid.
    [[ -z "${REPL_FQDN}" ]] && {
      LAST_ERR_MSG='FQDN cannot be empty'
      return ${NO}
    }
    host "${REPL_FQDN}" >/dev/null 2>&1 || {
      LAST_ERR_MSG="DNS lookup failed for FQDN '${REPL_FQDN}'"
      return ${NO}
    }
  fi
  REPL_FQDN_IS_VALID=${YES}
  return ${REPL_FQDN_IS_VALID}
}


validate_passwd() {
  if [[ ${REPL_PASSWD_IS_VALID} -eq ${NO} ]] ; then
    # All must pass for password to be valid.
    [[ -z "${REPL_PASSWD}" ]] && {
      LAST_ERR_MSG='Password cannot be empty'
      return ${NO}
    }
    [[ "${#REPL_PASSWD}" -lt 20 ]] && {
      LAST_ERR_MSG='Password too short'
      return ${NO}
    }
    REPL_PASSWD_IS_VALID=${YES}
  fi
  return ${REPL_PASSWD_IS_VALID}
}


validate_cn() {
  if [[ ${REPL_CN_IS_VALID} -eq ${NO} ]] ; then
    # All must pass for CN to be valid.
    [[ -z "${#REPL_CN}" ]] && {
      LAST_ERR_MSG='CN cannot be empty'
      return ${NO}
    }
    [[ "${#REPL_CN}" -lt 6 ]] && {
      LAST_ERR_MSG='CN too short'
      return ${NO}
    }
    REPL_CN_IS_VALID=${YES}
  fi
  return ${REPL_CN_IS_VALID}
}


validate_port() {
  if [[ ${REPL_PORT_IS_VALID} -eq ${NO} ]] ; then
    # If not set, default to 636
    [[ -z "${#REPL_PORT}" ]] && REPL_PORT=636
    if [[ "${#REPL_PORT}" == "636" ]] || [[ "${#REPL_PORT}" == "389" ]] ; then
      : pass
    else
      LAST_ERR_MSG="invalid PORT '${LDAP_PORT}', must be 389 or 636"
      return ${NO}
    fi
    REPL_PORT_IS_VALID=${YES}
  fi
  return ${REPL_PORT_IS_VALID}
}



add_ra() {
  validate_fqdn || die "${LAST_ERR_MSG}"
  validate_cn || die "${LAST_ERR_MSG}"
  validate_passwd || die "${LAST_ERR_MSG}"
  validate_port || die "${LAST_ERR_MSG}"
  cat <<ENDHERE | do_ldap_modify
dn: ${REPL_DN}
changetype: add
objectclass: top
objectclass: nsds5replicationagreement
cn: ${REPL_CN}
nsds5replicahost: ${REPL_FQDN}
nsds5replicaport: ${REPL_PORT}
nsds5ReplicaBindDN: cn=replication manager,cn=config
nsDS5ReplicaTransportInfo: SSL
nsds5replicabindmethod: SIMPLE
nsds5replicaroot: dc=ncsa,dc=illinois,dc=edu
description: replication agreement from ${HOST} to ${REPL_HOST}
nsds5replicacredentials: ${REPL_PASSWD}
nsds5BeginReplicaRefresh: start
ENDHERE

}


del_ra() {
  validate_cn || die "${LAST_ERR_MSG}"
  cat <<ENDHERE | do_ldap_modify
dn: ${REPL_DN}
changetype: delete
ENDHERE

}

init_ra() {
  validate_cn || die "${LAST_ERR_MSG}"
  cat <<ENDHERE | do_ldap_modify
dn: ${REPL_DN}
changetype: modify
replace: nsds5BeginReplicaRefresh
nsds5BeginReplicaRefresh: start
ENDHERE

}

pause_ra() {
  validate_cn || die "${LAST_ERR_MSG}"
  cat <<ENDHERE | do_ldap_modify
dn: ${REPL_DN}
changetype: modify
replace: nsds5ReplicaEnabled
nsds5ReplicaEnabled: off
ENDHERE

}


resume_ra() {
  validate_cn || die "${LAST_ERR_MSG}"
  cat <<ENDHERE | do_ldap_modify
dn: ${REPL_DN}
changetype: modify
replace: nsds5ReplicaEnabled
nsds5ReplicaEnabled: on
ENDHERE

}


print_usage() {
  echo
  cat <<ENDHERE
${PRG} [OPTIONS] <ACTION>
  OPTIONS
    -h | --help
    --cn <CN>      the cn of an existing replication agreement
    --host <FQDN>  the fqdn of the host whose replication agreement is to be affected
    --pwd <PWD>    replication manager password (as defined on HOST)

  ACTIONS
      add, delete, pause, resume, init

  NOTES:
    * if CN is not specified, create as 'ra_<FQDN>' using short hostname
    * (that means any action can use --host instead of --cn)
    * if both --host and --cn are specified, last one wins
    * --host is required for "add" action
    * --pwd is required for "add" action. Otherwise it is ignored.
ENDHERE
  echo
}



###
# MAIN
###

# Process options
ENDWHILE=0
while [[ $# -gt 0 ]] && [[ $ENDWHILE -eq 0 ]] ; do
  case $1 in
    -h|--help) print_usage; exit 0;;
    --cn)
      REPL_CN="$2"
      validate_cn || die "${LAST_ERR_MSG}"
      shift;;
    --host)
      REPL_FQDN="$2"
      validate_fqdn || die "${LAST_ERR_MSG}"
      mk_cn_from_host
      shift;;
    --pwd)
      REPL_PASSWD="$2";
      validate_passwd || die "${LAST_ERR_MSG}"
      shift;;
    --port)
      REPL_PORT="$2";
      validate_port || die "${LAST_ERR_MSG}"
      shift;;
    --) ENDWHILE=1;;
    -*) echo "Invalid option '$1'"; exit 1;;
     *) ENDWHILE=1; break;;
  esac
  shift
done

ACTION="${1}"

# this is common to every action, so just call it here
mk_dn

case "${ACTION}" in
  add)
    add_ra
    ;;
  del | delete | rm | remove)
    del_ra
    ;;
  pause)
    pause_ra
    ;;
  resume)
    resume_ra
    ;;
  init | initialize)
    init_ra
    ;;
  *)
    die "unknown ACTION"
    ;;
esac
