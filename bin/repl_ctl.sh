#!/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

PRG=$( basename "$0" )

REPL_FQDN_IS_VALID=${NO}
REPL_PASSWD_IS_VALID=${NO}
REPL_CN_IS_VALID=${NO}
LAST_ERR_MSG='?'



mk_cn_from_host() {
  REPL_HOST=$( echo "${REPL_FQDN}" | awk -F '.' '{print $1}' )
  REPL_CN="replication_agreement_${REPL_HOST}"
}


# mk_dn() {
#   REPL_DN="cn=${REPL_CN},cn=replica,cn=\"${DS_SUFFIX}\",cn=mapping tree,cn=config"
# }


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


add_ra() {
  validate_fqdn || die "${LAST_ERR_MSG}"
  validate_cn || die "${LAST_ERR_MSG}"
  validate_passwd || die "${LAST_ERR_MSG}"
  _dsconf \
    repl-agmt create \
    --host "${REPL_FQDN}" \
    --port "${REPL_PORT}" \
    --conn-protocol="${REPL_PROTOCOL}" \
    --suffix "${DS_SUFFIX}" \
    --bind-dn "${REPL_DN}" \
    --bind-method SIMPLE \
    --bind-passwd "${REPL_PASSWD}" \
    --init "${REPL_CN}"
}


add_ra_to_dsrc() {
  DSRC=~/.dsrc
  grep -q '[repl-monitor-connections]' "${DSRC}" || {
    echo '[repl-monitor-connections]' >> "${DSRC}"
  }
  grep -q "${REPL_CN}" "${DSRC}" || {
    cat <<ENDHERE >>"${DSRC}"
${REPL_CN} = ${REPL_FQDN}:${REPL_PORT}:${REPL_DN}:${REPL_PASSWD}
ENDHERE
  }
}


del_ra() {
  validate_cn || die "${LAST_ERR_MSG}"
  _dsconf \
    repl-agmt delete \
    --suffix "${DS_SUFFIX}" \
    "${REPL_CN}"
}


init_ra() {
  validate_cn || die "${LAST_ERR_MSG}"
  _dsconf \
    repl-agmt init \
    "${REPL_CN}"
}


pause_ra() {
  validate_cn || die "${LAST_ERR_MSG}"
  _dsconf \
    repl-agmt disable \
    --suffix "${DS_SUFFIX}" \
    "${REPL_CN}"
}


resume_ra() {
  validate_cn || die "${LAST_ERR_MSG}"
  _dsconf \
    repl-agmt enable \
    --suffix "${DS_SUFFIX}" \
    "${REPL_CN}"
}


poke_ra() {
  validate_cn || die "${LAST_ERR_MSG}"
  _dsconf \
    repl-agmt poke \
    --suffix "${DS_SUFFIX}" \
    "${REPL_CN}"
}


list_all() {
  _dsconf \
    repl-agmt list \
    --suffix "${DS_SUFFIX}"
}


list_ra() {
  validate_cn || die "${LAST_ERR_MSG}"
  _dsconf \
    repl-agmt get \
    --suffix "${DS_SUFFIX}" \
    "${REPL_CN}"
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
      add, delete, pause, resume, init, poke, list 

  NOTES:
    * if CN is not specified, create as 'replication_agreement_<FQDN>'
      using short hostname
    * (that means any action can use --host instead of --cn)
    * if both --host and --cn are specified, last one wins
    * --host is required for "add" action
    * --pwd is required for "add" action. Otherwise it is ignored.
    * if --host is provided for "list" action, then show all the details for that
      repl-agmt only. Otherwise, "list" by itself will show all repl-agmt's
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
    --) ENDWHILE=1;;
    -*) echo "Invalid option '$1'"; exit 1;;
     *) ENDWHILE=1; break;;
  esac
  shift
done

ACTION="${1}"

# this is common to every action, so just call it here
#mk_dn

case "${ACTION}" in
  add)
    add_ra
    # add_ra_to_dsrc
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
  poke)
    poke_ra
    ;;
  list)
    if [[ "${REPL_FQDN_IS_VALID}" -eq ${YES} ]] ; then
      list_ra
    else
      list_all
    fi
    ;;
  *)
    die "unknown ACTION"
    ;;
esac
