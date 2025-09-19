#!/usr/bin/bash

# set -x

HOST=ldap-auth4.ncsa.illinois.edu
RUNTIME=3600
BASE='ou=People,dc=ncsa,dc=illinois,dc=edu'
FILTER='uid=aloftus'
ATTRS=( uid cn givenName sn mail employeeType memberOf )
YES=0
NO=1

do_search() {
  # set -x
  ldapsearch \
    -x \
    -H ldaps://"${HOST}" \
    -b "${BASE}" \
    "scope=2" \
    "${FILTER}" \
    "${ATTRS[@]}" >/dev/null
}


lessthan() {
  result=$( bc <<<"$1 < $2" )
  if [[ $result -eq 0 ]] ; then
    /bin/false
  else
    /bin/true
  fi
}

greaterthan() {
  result=$( bc <<<"$1 > $2" )
  if [[ $result -eq 0 ]] ; then
    /bin/false
  else
    /bin/true
  fi
}

print_summary() {
  echo
  echo "Ended after ${counter} iterations"
  for log in "${long_runs[@]}" ; do
    echo "${log}"
  done
}


###
# MAIN
###

# Allow setting HOST on cmdline
[[ "${#}" -gt 0 ]] && {
  HOST="${1}"
  shift
}
# echo "HOST: $HOST"

# Allow setting RUNTIME on cmdline
[[ "${#}" -gt 0 ]] && {
  RUNTIME="${1}"
  shift
}
# echo "RUNTIME: $RUNTIME"
# exit 1


print_min=10
counter=0
show_progress=$YES
show_iterations=$YES
long_runs=()
while lessthan "${SECONDS}" "${RUNTIME}" ; do
  tstart=$(date +%s.%N)
  do_search
  tend=$(date +%s.%N)
  elapsed=$( echo "$tend - $tstart" | bc);
  # elapsed=$( { time do_search >/dev/null ; } 2>&1 )
  # echo "${elapsed}" "${print_min}" 
  greaterthan "${elapsed}" "${print_min}" && {
    dt=$(date +"%Y-%m-%d:%H:%M:%S %Z")
    log="${elapsed} ${dt}"
    long_runs+=("${log}")
    echo
    echo "${log}"
  }
  ((counter++))
  remainder=$( bc <<<"${counter} % 100" )
  dot_mainder=$( bc <<<"${remainder} % 5" )
  if [[ ${show_iterations} -eq ${YES} ]] ; then
    [[ "${remainder}" -eq 0 ]] && {
      echo
      echo -n "${counter} iterations "
      date
    }
  fi
  if [[ ${show_progress} -eq $YES ]] ; then
    [[ "${dot_mainder}" -eq 0 ]] && echo -n "."
  fi
  sleep 1
done

print_summary
