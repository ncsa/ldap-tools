#!/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

PRG=$( basename "$0" )
BIN="${INSTALL_DIR}"/bin
JQ="${BIN}"/jq
OUTDIR=/var/log/dirsrv/slapd-ldap/post_processed_logs
TMP="${OUTDIR}"/client_access_summary_tmp.json
DEBUG=$NO


count_client_actions() {
  [[ $DEBUG -eq $YES ]] && set -x
  "${JQ}" -n -f "${BIN}"/count_client_actions.jq <"${TMP}" \
  | tr -c '[:alnum:][:space:].' ' ' \
  | awk -f filter_client_actions.awk \
  | sort -k1n,1
}


get_time_period() {
  [[ $DEBUG -eq $YES ]] && set -x
  ( head -1; tail -1 ) <"${TMP}" \
  | "${JQ}" -n -f "${BIN}"/duration.jq
}


validate_file() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _fn="${1}"
  [[ -f "${_fn}" ]] || {
    LAST_ERR_MSG="File not found: '${_fn}'"
    return ${NO}
  }
  [[ -r "${_fn}" ]] || {
    LAST_ERR_MSG="File not readable: '${_fn}'"
    return ${NO}
  }
  [[ -s "${_fn}" ]] || {
    LAST_ERR_MSG="File is 0 size: '${_fn}'"
    return ${NO}
  }
}


cleanup() {
  rm -f "${TMP}"
}


print_usage() {
  echo
  cat <<ENDHERE
Count unique actions per client in a JSON access log.

${PRG} [OPTIONS] <FILE1> [FILE2]...
  OPTIONS
    -h | --help
    -d | --debug
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
    -d | --debug) DEBUG=$YES;;
    --) ENDWHILE=1;;
    -*) echo "Invalid option '$1'"; exit 1;;
     *) ENDWHILE=1; break;;
  esac
  shift
done

# Validate input files
[[ $# < 1 ]] && die "missing input filenames"
for fn in "${@}" ; do
  validate_file "${fn}" || die "${LAST_ERR_MSG}"
done

# Combine multiple input files into one
>"${TMP}" cat "${@}"

count_client_actions

get_time_period

cleanup
