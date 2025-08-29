#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

LAP="${INSTALL_DIR}"/bin/lap
EVENT_PARSER="${INSTALL_DIR}"/bin/eventparser.py
TMP_JSON="${INSTALL_DIR}"/live/logs.json


get_access_logs() {
  find "${DS_LOGDIR}" \
    -maxdepth 1 \
    -mindepth 1 \
    -name 'access*' \
    -not -name '*.rotationinfo'
}


process_raw_logs() {
  : >"${TMP_JSON}" #truncate file
  for f in $( get_access_logs ); do
    "${LAP}" "${f}" >>"${TMP_JSON}"
  done
}


filter_events() {
  "${DS_PY3}" "${EVENT_PARSER}" "${TMP_JSON}" "${@}"
}


cleanup() {
  rm -f "${TMP_JSON}" 2>/dev/null
}

###
# MAIN
###

# short circuit everything if call for help
case "${1}" in
  -h|--help)
    "${DS_PY3}" "${EVENT_PARSER}" -h
    exit 0
    ;;
esac

process_raw_logs

filter_events "${@}"
