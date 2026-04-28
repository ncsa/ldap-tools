#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


# replication ids, see also:
# https://www.port389.org/docs/389ds/design/architecture.html
mk_rep_id() {
  ### make replication id
  #   roles "consumer" and "hub" are always 65535
  #   role "supplier" will be hostnum + hosttype
  #     where hosttype is either "test" or "dev" or empty
  #     and where "test" = 100 and "dev" = 200
  #     Example; isf-ldaprw-01-dev:  replication_id = 201
  #     Example; isf-ldaprw-02-test: replication_id = 102
  #     Example; isf-ldaprw-03:      replication_id = 3
  ###
  local _rep_id _parts _hostnum _hosttype _scalar
  _scalar=0
  case "${role}" in
    'consumer' | 'hub' )
      _rep_id=65535
      ;;
    'supplier' )
      _hostnum=$( echo "${HOST}" | cut -d. -f1 | cut -d- -f3 )
      _hosttype=$( echo "${HOST}" | cut -d. -f1 | cut -d'-' -f4 )
      if [[ -n "${_hosttype}" ]] ; then
        case "${_hosttype}" in
           dev) _scalar=200;;
          test) _scalar=100;;
             *) die "unknown host type '${_hosttype}'";;
        esac
      fi
      _rep_id=$( bc <<< "${_hostnum} + ${_scalar}" )
      ;;
    *)
      die "unknown replica role '${role}'"
      ;;
  esac
  echo "${_rep_id}"
}


create_replication_agreement() {
  _dsconf \
    replication enable \
    --role "${role}" \
    --replica-id "${rep_id}" \
    --suffix "${DS_SUFFIX}" \
    --bind-dn "${REPL_DN}" \
    --bind-passwd-file "${REPL_PW_FN}"
}


check_replication_agreement() {
  _dsconf \
    replication get \
    --suffix "${DS_SUFFIX}"
}


print_report() {
  success "Node configured as a replication ${role}."
  case "${role}" in
    'hub' | 'consumer' )
      cat <<ENDHERE
Replication id: ${rep_id}
Replication pwd: "$( cat ${REPL_PW_FN} )"
Replication pwd file: ${REPL_PW_FN}

On the SUPPLIER server, run:
${INSTALL_DIR}/bin/repl_ctl.sh \\
--host ${HOST} \\
--pwd $( cat ${REPL_PW_FN} ) \\
add
ENDHERE
      ;;
  esac
}


###
# MAIN
###

role="${1}"
rep_id=$( mk_rep_id ) #this will die if role is missing or bad

create_replication_agreement

check_replication_agreement

print_report
