#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


# replication ids, see also:
# https://www.port389.org/docs/389ds/design/architecture.html
mk_rep_id() {
  local _rep_id=
  case "${role}" in
    'supplier' )
      _rep_id=$( echo "${HOST}" | cut -d. -f1 | tr -cd '[0-9]' )
      ;;
    'consumer' | 'hub' )
      _rep_id=65535
      ;;
    *)
      die "unknown replica role '${role}'"
      ;;
  esac
  echo "${_rep_id}"
  return 0
}


create_replication_agreement() {
  _dsconf \
    replication enable \
    --role "${role}" \
    --replica-id "${rep_id}" \
    --suffix "${DS_SUFFIX}" \
    --bind-dn "${REPL_DN}" \
    --bind-passwd-file "${REPLPW_FN}"
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
Replication pwd: "$( cat ${REPLPW_FN} )"
Replication pwd file: ${REPLPW_FN}

On the SUPPLIER server, run:
${INSTALL_DIR}/bin/repl_ctl.sh \\
--host ${HOST} \\
--pwd $( cat ${REPLPW_FN} ) \\
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
