#!/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

PRG=$( basename "$0" )

LAP="${INSTALL_DIR}"/bin/lap
JQ="${INSTALL_DIR}"/bin/jq
OUTDIR=/var/log/dirsrv/slapd-ldap/post_processed_logs
TMP="${OUTDIR}"/lap_output.json
# ACCESS_LOG=/var/log/dirsrv/slapd-ldap/access
FN_PFX=
OUTFN=_access_log.json
DEBUG=$YES


process_logs() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _start
  local _end
  local _elapsed
  >"${TMP}"
  for f in "${@}"; do
    _start=$SECONDS
    "${LAP}" "${f}" >> "${TMP}"
    _end=$SECONDS
    _elapsed=$( bc <<< "${_end} - ${_start}" )
    echo "Processed '$f' in ${_elapsed} secs"
  done
  ls -l "${TMP}"
}


mk_fn_date_pfx() {
  [[ $DEBUG -eq $YES ]] && set -x
  # make a filename prefix using the last timestamp from LAP json output
  local _ts=$( tail -1 "${TMP}" \
    | "${JQ}" '.time[:20] | strptime("%d/%b/%Y:%H:%M:%S") | mktime'
  )
  FN_PFX=$( date -d @"${_ts}" +%Y%m%dT%H%M%S )
}


validate_outdir() {
  [[ $DEBUG -eq $YES ]] && set -x
  [[ -d "${OUTDIR}" ]] || {
    LAST_ERR_MSG="Directory not found: '${OUTDIR}'"
    return ${NO}
  }
  return ${YES}
}


validate_prefix() {
  [[ $DEBUG -eq $YES ]] && set -x
  [[ -z "${FN_PFX}" ]] && {
    LAST_ERR_MSG='Prefix cannot be empty'
    return ${NO}
  }
  return ${YES}
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


print_usage() {
  echo
  cat <<ENDHERE
Process raw ds389 access logs into useful JSON format.

${PRG} [OPTIONS] <accesslogfile> [accesslogfile]...
  OPTIONS
    -h | --help
    -o | --outdir <DIR>
            Where to write JSON output files
            Default: '${OUTDIR}'
    -p | --prefix <PREFIX>
            Output file prefix
            Default: use the date prefix from the first input file

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
    -o | --outdir)
      OUTDIR="$2"
      validate_outdir || die "${LAST_ERR_MSG}"
      shift;;
    -p | --prefix)
      FN_PFX="$2"
      validate_prefix || die "${LAST_ERR_MSG}"
      shift;;
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


process_logs "${@}"

[[ -z "${FN_PFX}" ]] && mk_fn_date_pfx "${1}"

final_outfn="${OUTDIR}"/"${FN_PFX}"_"${OUTFN}"
mv "${TMP}" "${final_outfn}"
ll "${final_outfn}"
