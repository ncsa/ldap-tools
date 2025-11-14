#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

LAP_DIR="${INSTALL_DIR}"/lap
TMP_DIR="${INSTALL_DIR}"/temp
GO="${TMP_DIR}"/go/bin/go
TS="$( date +%c )"

set -x


install_go() {
  local _url _tgz _version
  _version='1.25.4'
  _url=https://go.dev/dl/go"${_version}".linux-amd64.tar.gz
  _tgz=go"${_version}".linux-amd64.tar.gz
  [[ -d "${TMP_DIR}" ]] || {
    mkdir "${TMP_DIR}"
    pushd "${TMP_DIR}"
    wget "${_url}"
    tar -zxf "${_tgz}"
    rm "${_tgz}"
    popd
  }
}


install_lap() {
  local _target=ldap_access_parser
  [[ -f "${INSTALL_DIR}"/bin/"${_target}" ]] || {
    install_go
    # build an executable
    pushd "${LAP_DIR}"
    "${GO}" mod init "${_target}"
    "${GO}" mod tidy
    "${GO}" build
    popd
    # install the executable
    install \
      --verbose \
      -t "${INSTALL_DIR}"/bin \
      "${LAP_DIR}"/"${_target}"
  }
}


install_jq() {
  local _url _outfile
  _url=https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-linux-amd64
  _outfile="${INSTALL_DIR}"/bin/jq
  if [[ ! -f "${_outfile}" ]] ; then
    curl -L -o "${_outfile}" "${_url}"
    chmod +x "${_outfile}"
  fi
}


setup_venv() {
  local _system_py3
  _system_py3=$( which python3 )

  [[ -x "${_system_py3}" ]] || die "python3 not found"

  [[ -d "${DS_VENV}" ]] || {
    # make venv
    "${_system_py3}" -m venv "${DS_VENV}" || die "error during make venv"
    # update pip
    "${DS_PY3}" -m pip install --upgrade pip
    # install dependencies
    "${DS_PY3}" -m pip install -r "${INSTALL_DIR}"/files/python_deps.txt
  }
}


mk_post_logdir() {
  [[ -d "${POST_LOG_DIR}" ]] || {
    mkdir "${POST_LOG_DIR}"
  }
}


cmd_in_cron() {
  local _cmd
  _cmd="${1}"
  crontab -l | grep -q -F "${_cmd}"
}


add_to_cron() {
  local _cmd _when
  _cmd="${1}"
  _when="${2}"
  ( crontab -l
    echo "# installed by ldap-tools on ${TS}"
    echo "SHELL=/bin/bash"
    echo "${_when} ${_cmd}"
  ) | crontab -
}


install_hourly_crons() {
  local _crondir _cron_files _fn _hour _min _cmd
  _crondir="${INSTALL_DIR}"/cron
  _cron_files=( $( find "${_crondir}" \
    -mindepth 1 -maxdepth 1 -type f -executable -regextype posix-egrep
      -regex '.+/[0-9]{4}_.+\.sh$'
  ) )
  for i in "${!_cron_files[@]}"; do
    _cmd="${_cron_files[$i]}"
    # get hour from first two digits of filename
    _fn=$( basename "${_cmd}" )
    _hour="${_fn:0:2}"
    _min="${_fn:2:2}"
    if ! cmd_in_cron "${_cmd}" ; then
      add_to_cron "${_cmd}" "${_min} ${_hour} * * *"
    fi
  done
}


setup_lap_service() {
  # Install the appropriate systemd service file,
  # ... based on local systemd version
  local _systemd_version _src _tgt
  _systemd_version=$( systemctl --version | head -1 | awk '{print $2}' )
  _tgt=/etc/systemd/system/ldap_access_parser.service
  _src="${_tgt}"
  if [[ "${_systemd_version}" -lt 249 ]] ; then
    _src=ldap_access_parser.v10.service
  fi
  _src="${INSTALL_DIR}"/files/etc/systemd/"${_src}"
  # set logdir path in systemd file, write output to target
  sed -e "s?___DS_LOG_DIR___?${DS_LOG_DIR}?" "${_src}" >"${_tgt}"
  # pushd /etc/systemd/system
  # ln -sf "${INSTALL_DIR}"/files/etc/systemd/"${_src}" "${_tgt}"
  # ln -sf "${_tgt}" lap.service
  # popd
  systemctl daemon-reload
}


cleanup() {
  rm -rf "${LAP_DIR}"
  rm -rf "${TMP_DIR}"
  rm -f "${INSTALL_DIR}"/bin/go.mod
}


###
# MAIN
###

install_lap

install_jq

setup_venv

mk_post_logdir

# setup_lap_service

install_hourly_crons

cleanup
