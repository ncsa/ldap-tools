#!/usr/bin/bash


INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

PRG=$( basename "$0" )
YES=0
NO=1
AUTO_YES=${NO}

dump_db() {
  local _ts_start=$SECONDS
  _dsctl db2ldif --replication userRoot
  local _ts_end=$SECONDS
  local _elapsed=$( bc <<< "$_ts_end - $_ts_start" )
  echo "Database backup took: ${_elapsed} secs"

  local _ldif_out_fn=$( ls -t "${DS_LDIF_DIR}" | head -1)
  local _src="${DS_LDIF_DIR}"/"${_ldif_out_fn}"
  local _tgt=/tmp/replcheck_"${HOST}"."${_ldif_out_fn}"
  # ln -s -r "${DS_LDIF_DIR}"/"${_ldif_out_fn}" "${DS_LDIF_DIR}"/replcheck_${HOST}.ldif
  mv "${_src}" "${_tgt}"
  chmod o+r "${_tgt}"
  echo  "Bkup LDIF: '${_tgt}'"

  echo -n 'Entries in DB: '
  grep '^dn: ' "${_tgt}" | wc -l
}


purge_old() {
  rm -f /tmp/replcheck_*.ldif
}


print_usage() {
  echo
  cat <<ENDHERE
${PRG} [OPTIONS] <ACTION>
  OPTIONS
    -h | --help   Print this help msg
    -y | --yes     Answer Yes to all questions
ENDHERE
  echo
}



###
# MAIN
###
#
# Process options
ENDWHILE=${NO}
while [[ $# -gt 0 ]] && [[ $ENDWHILE -eq ${NO} ]] ; do
  case $1 in
    -h|--help) print_usage; exit 0;;
    -y | --yes)
      AUTO_YES=${YES}
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

ACTION="${1}"

[[ ${AUTO_YES} -ne ${YES} ]] \
&& continue_or_exit "DS389 will be stopped during the backup. Continue?"

purge_old

_dsctl stop

dump_db

_dsctl start
