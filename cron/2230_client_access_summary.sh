#!/bin/bash

# Count unique actions per client in a JSON access log.
# This script was designed to be run from cron.

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

PRG=$( basename "$0" )
BIN="${INSTALL_DIR}"/bin
JQ="${BIN}"/jq
AWK_FILTER="${BIN}"/filter_client_actions.awk
SRCDIR="${POST_LOG_DIR}"
OUTDIR="${SRCDIR}"
JSON_FILES_FN="${POST_LOG_DIR}"/"${PRG}".tmp


mk_outfn() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _infile
  _infile="${1}"
  json_2_outfn "${_infile}" '.clients.csv'
}


count_client_actions() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _infile
  _infile="${1}"
  "${JQ}" -n -R -f "${BIN}"/count_client_actions.jq <"${_infile}" \
  | tr -c '[:alnum:][:space:].' ' ' \
  | awk -f "${AWK_FILTER}" \
  | sort -k1n,1
}


process_logs() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _start
  local _end
  local _elapsed
  # For each json file listed in JSON_FILES_FN
  while read infile; do
    # Process the json contents from --> _infile <--
    local _outfn=$( mk_outfn "${infile}" )
    _start=$SECONDS
    if [[ $DEBUG -eq $YES ]] ; then
      echo "Would have run count_client_actions '${infile}' -> '${_outfn}'"
    else
      info "Processing '${infile}' ..."
      count_client_actions "${infile}" > "${_outfn}"
    fi
    _end=$SECONDS
    _elapsed=$( bc <<< "${_end} - ${_start}" )
    echo "Processed '${infile}' in ${_elapsed} secs"
  done <"${JSON_FILES_FN}"
}


cleanup() {
  rm -f "${JSON_FILES_FN}"
}


print_usage() {
  echo
  cat <<ENDHERE
Process ldap access json files to generate client access histories.

${PRG} [OPTIONS]
  OPTIONS
    -h | --help
    -d | --debug
    -v | --verbose  (tell about skipped files)
    -s | --srcdir <DIR>
            Location of json files
            Default: '${SRCDIR}'
    -o | --outdir <DIR>
            Where to write CSV output files
            Default: '${OUTDIR}'

  NOTES:
    * Works best when the ds389 access log is rotated daily at midnight
ENDHERE
  echo
}

###
# MAIN
###

[[ $DEBUG -eq $YES ]] && set -x

# Process options
ENDWHILE=0
while [[ $# -gt 0 ]] && [[ $ENDWHILE -eq 0 ]] ; do
  case $1 in
    -h | --help) print_usage; exit 0;;
    -v | --verbose) VERBOSE=$YES;;
    -d | --debug)
      VERBOSE=$YES
      DEBUG=$YES
      ;;
    -s | --srcdir)
      SRCDIR="$2"
      validate_dir "${SRCDIR}" || die "${LAST_ERR_MSG}"
      shift;;
    -o | --outdir)
      OUTDIR="$2"
      validate_dir "${OUTDIR}" || die "${LAST_ERR_MSG}"
      shift;;
    --) ENDWHILE=1;;
    -*) echo "Invalid option '$1'"; exit 1;;
     *) ENDWHILE=1; break;;
  esac
  shift
done

get_json_logs "${JSON_FILES_FN}"

process_logs

cleanup
