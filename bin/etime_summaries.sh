#!/bin/bash

# Generate etime summaries from ldap access log json files & send to syslog.
# This script was designed to be run from cron.

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

PRG=$( basename "$0" )
PROCESSOR="${INSTALL_DIR}"/bin/etime_report.py
SRCDIR=/var/log/dirsrv/slapd-"${DS_INSTANCE_NAME}"/post_processed_logs
OUTDIR="${SRCDIR}"
JSON_FILES=()
DEBUG=$NO
VERBOSE=$NO


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
  _pfx=$( basename "${_infile}" .json )
  echo "${OUTDIR}"/"${_pfx}".csv
}


get_json_files() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _sources
  local _fn_ok
  local _tgt_fn
  _sources=( $( ls "${SRCDIR}"/*.json ) )
  for infile in "${_sources[@]}"; do
    # check file is valid
    validate_file "${infile}" || {
      echo "skipping input file '${infile}', ${LAST_ERR_MSG}" 1>&2
      continue
    }
    # check file hasn't been processed yet
    _tgt_fn=$( mk_outfn "${infile}" )
    if [[ -f "${_tgt_fn}" ]] ; then
      info "skipping input file '${infile}', output file '${_tgt_fn}' already exists"
      continue
    fi
    JSON_FILES+=( "${infile}" )
  done
}


process_logs() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _start
  local _end
  local _elapsed
  for infile in "${JSON_FILES[@]}"; do
    local _outfn=$( mk_outfn "${infile}" )
    _start=$SECONDS
    if [[ $DEBUG -eq $YES ]] ; then
      echo "Would have run ${PROCESSOR} '${infile}' -> '${_outfn}'"
    else
      "${PROCESSOR}" -S -F csv "${infile}" > "${_outfn}"
    fi
    _end=$SECONDS
    _elapsed=$( bc <<< "${_end} - ${_start}" )
    echo "Processed '${infile}' in ${_elapsed} secs"
  done
}


print_usage() {
  echo
  cat <<ENDHERE
Process ldap access json files to generate etime summaries.

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

get_json_files

process_logs
