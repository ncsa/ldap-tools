#!/usr/bin/bash


INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

PRG=$( basename "$0" )
YES=0
NO=1


get_ds_version() {
  if [[ -f /sbin/db2ldif ]] ; then
    DS_VERSION=10
  elif [[ -f /usr/sbin/dsconf ]] ; then
    DS_VERSION=12
  else
    die "Unable to determine version of ds389"
  fi
}


db_dumper() {
  local _ts_start=$SECONDS
  "${@}"
  local _ts_end=$SECONDS
  local _elapsed=$( bc <<< "$_ts_end - $_ts_start" )
  echo "Database backup took: ${_elapsed} secs"

  local _ldif_out_fn=$( ls -t "${DS_LDIF_DIR}" | head -1)
  [[ -f "${_ldif_out_fn}" ]] || die "unable to find db dump ldif"

  local _src="${DS_LDIF_DIR}"/"${_ldif_out_fn}"
  local _tgt=/tmp/replcheck."${_ldif_out_fn}"
  mv "${_src}" "${_tgt}"
  chmod o+r "${_tgt}"
  echo  "Bkup LDIF: '${_tgt}'"

  echo -n 'Entries in DB: '
  grep '^dn: ' "${_tgt}" | wc -l
}


dump_db() {
  if [[ "${DS_VERSION}" -eq 10 ]] ; then
    cmd='/sbin/db2ldif'
    parms=( '-s' "${DS_SUFFIX}" )
  else
    cmd='_dsctl'
    parms=( db2ldif userRoot )
  fi
  db_dumper "${cmd}" "${parms[@]}"
}


stop_service() {
  if [[ "${DS_VERSION}" -eq 10 ]] ; then
    systemctl stop "${LDAP_SERVICE_NAME}"
  else
    _dsctl stop
  fi
}


start_service() {
  if [[ "${DS_VERSION}" -eq 10 ]] ; then
    systemctl start "${LDAP_SERVICE_NAME}"
  else
    _dsctl start
  fi
}


purge_old() {
  rm -f /tmp/replcheck_*.ldif
}


print_usage() {
  echo
  cat <<ENDHERE
${PRG} [OPTIONS]
  OPTIONS
    -h | --help     Print this help msg
    -y | --yes      Answer Yes to all questions (use in conjunction with --offline)
    -o | --offline  Stop the server during the dump
ENDHERE
  echo
}



###
# MAIN
###
#
# Process options
AUTO_YES=${NO}
OFFLINE=${NO}
ENDWHILE=${NO}
while [[ $# -gt 0 ]] && [[ $ENDWHILE -eq ${NO} ]] ; do
  case $1 in
    -h|--help)
      print_usage
      exit 0
      ;;
    -y | --yes)
      AUTO_YES=${YES}
      ;;
    -o | --offline)
      OFFLINE=${YES}
      ;;
    --)
      ENDWHILE=${YES}
      ;;
    -*)
      echo "Invalid option '$1'"
      exit 1
      ;;
     *)
       ENDWHILE=${YES}
       break;;
  esac
  shift
done

[[ ${OFFLINE} -eq ${YES} && ${AUTO_YES} -ne ${YES} ]] \
&& continue_or_exit "DS389 will be stopped during the backup. Continue?"

purge_old

# [[ ${OFFLINE} -eq ${YES} ]] && stop_service

dump_db

# [[ ${OFFLINE} -eq ${YES} ]] && start_service
