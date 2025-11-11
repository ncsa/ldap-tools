#!/usr/bin/bash

PRG=$( basename "$0" )
LDAP_TOOLS_DIR=/root/ldap-tools
BIN="${LDAP_TOOLS_DIR}"/bin


die() {
  echo "ERROR: ${@}"
  exit 1
}


assert_valid_host() {
  local _host_raw="${1}"
  [[ -z "${_host_raw}" ]] && die "Empty hostname"
  local _output=$( host "${_host_raw}" | head -1 )
  # local _rc=$?
  # echo "host rc: '$_rc'"
  echo "output: '${_output}'"
  # [[ "${_output}" == *" has address "* ]] || die "Invalid hostname"
  if [[ "${_output}" != *" has address "* ]] ; then
    die "Invalid hostname: '$_host_raw'"
  fi
}


remote_dump_db() {
  local _host="${1}"
  ssh "${_host}" "${BIN}"/dump_db.sh
}

print_usage() {
  cat <<ENDHERE

${PRG}
  Dump ldap database on each host,
  Transfer dbdumps to HOST2 (or TGT using --target),
  Run ds-replcheck on the two dbdump files.

SYNOPSIS
  ${PRG} [OPTIONS] HOST1 HOST2

    OPTIONS
      -h | --help
      -t | --target  Host on which to run the ldif comparison.
                     Defaults to HOST2.
      -p | --path    Path to ldap-tools directory on remote hosts.
                     Defaults to /root/ldap-tools.
    NOTES:
      * hosts can be short hostname

ENDHERE
}



###
# MAIN
###

set -x

# Process options
ENDWHILE=0
while [[ $# -gt 0 ]] && [[ $ENDWHILE -eq 0 ]] ; do
  case $1 in
    -h|--help)
      print_usage
      exit 0
      ;;
    -t | --target)
      TGT="${2}"
      assert_valid_host "${TGT}"
      shift
      ;;
    -p | --path)
      LDAP_TOOLS_DIR="${2}"
      BIN="${LDAP_TOOLS_DIR}"/bin
      shift
      ;;
    --) ENDWHILE=1;;
    -*) echo "Invalid option '$1'"; exit 1;;
     *) ENDWHILE=1; break;;
  esac
  shift
done

HOST1="${1}"
HOST2="${2}"

assert_valid_host "${HOST1}"
assert_valid_host "${HOST2}"
[[ -z "${TGT}" ]] && TGT="${HOST2}" # if tgt not specified, use HOST2

# remote_dump_db "${HOST1}"
# remote_dump_db "${HOST2}"

# for h in "${HOST1}" "${HOST2}" ; do
#   scp -3 "${h}":/tmp/replcheck.ldif "${TGT}":/tmp/"${h}".ldif
# done

DS_REPLCHECK=/usr/bin/ds-replcheck
F1=/tmp/"${HOST1}".ldif
F2=/tmp/"${HOST2}".ldif
OUTFILE=/tmp/replcheck.out
ssh "${TGT}" \
  "${DS_REPLCHECK}" offline \
  -m "${F1}" \
  -r "${F2}" \
  -b 'dc=ncsa,dc=illinois,dc=edu' \
  --rid 1 \
  -o "${OUTFILE}"
