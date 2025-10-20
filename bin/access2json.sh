#!/bin/bash

# Post-process completed ds389 access logs into a more usable JSON format.
# This script was designed to be run from cron.

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

PRG=$( basename "$0" )
LAP="${INSTALL_DIR}"/bin/lap
ACCESS_LOGDIR=/var/log/dirsrv/slapd-"${DS_INSTANCE_NAME}"
OUTDIR=/var/log/dirsrv/slapd-"${DS_INSTANCE_NAME}"/post_processed_logs
ACCESS_LOGS=()
DEBUG=$NO


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
  return ${YES}
}


validate_dir() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _dir="${1}"
  [[ -d "${_dir}" ]] || {
    LAST_ERR_MSG="Directory not found: '${_dir}'"
    return ${NO}
  }
  return ${YES}
}


mk_outfn() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _infile
  local _pfx
  _infile="${1}"
  _pfx=$( echo "${_infile}" | cut -c -15 )
  echo "${OUTDIR}"/"${_pfx}".json
}


get_access_logs() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _raw_logs
  local _fn_ok
  local _tgt_fn
  _raw_logs=( $( ls "${ACCESS_LOGDIR}"/access.[0-9]* ) )
  for infile in "${_raw_logs[@]}"; do
    # check file is valid
    validate_file "${infile}" || {
      echo "skipping input file '${infile}', ${LAST_ERR_MSG}" 1>&2
      continue
    }
    # check file hasn't been processed yet
    _tgt_fn=$( mk_outfn "${infile}" )
    if [[ -f "${_tgt_fn}" ]] ; then
      echo "skipping input file '${infile}', output file '${_tgt_fn}' alread exists" 1>&2
      continue
    fi
    ACCESS_LOGS+=( "${infile}" )
  done
}


process_logs() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _start
  local _end
  local _elapsed
  for infile in "${ACCESS_LOGS[@]}"; do
    local _outfn=$( mk_outfn "${infile}" )
    _start=$SECONDS
    #"${LAP}" "${infile}" >> "${_outfn}"
    local _action
    local _redirect ; _redirect='>>'
    [[ $DEBUG -eq $YES ]] && {
      _action='echo'
      _redirect='redirected to'
    }
    ${_action} "${LAP}" "${infile}" ${_redirect} "${_outfn}"
    _end=$SECONDS
    _elapsed=$( bc <<< "${_end} - ${_start}" )
    echo "Processed '${infile}' in ${_elapsed} secs"
  done
}


print_usage() {
  echo
  cat <<ENDHERE
Process raw ds389 access logs into useful JSON format.

${PRG} [OPTIONS] <accesslogfile> [accesslogfile]...
  OPTIONS
    -h | --help
    -d | --debug
    -a | --access_log_dir <DIR>
            Location of ds389 raw access logs
            Default: '${ACCESS_LOGDIR}'
    -o | --outdir <DIR>
            Where to write JSON output files
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
    -d | --debug) DEBUG=$YES;;
    -a | --access_log_dir)
      ACCESS_LOGDIR="$2"
      validate_dir "${ACCESS_LOGDIR}" || die "${LAST_ERR_MSG}"
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

get_access_logs

process_logs
