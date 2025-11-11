#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh

LAP_DIR="${INSTALL_DIR}"/lap
TMP_DIR="${INSTALL_DIR}"/temp
GO="${TMP_DIR}"/go/bin/go

set -x


install_go() {
  local _url _tgz
  _url=https://go.dev/dl/go1.25.0.linux-amd64.tar.gz
  _tgz=go1.25.0.linux-amd64.tar.gz
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
  [[ -f "${INSTALL_DIR}"/bin/lap ]] || {
    # build an executable
    pushd "${LAP_DIR}"
    "${GO}" mod init lap
    "${GO}" mod tidy
    "${GO}" build
    popd
    # install the executable
    install \
      --verbose \
      -t "${INSTALL_DIR}"/bin \
      "${LAP_DIR}"/lap
  }
}


install_jq() {
  local _url _outfile
  _url=https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-linux-amd64
  _outfile="${INSTALL_DIR}"/bin/jq "${_url}"
  curl -L -o "${_outfile}" "${_url}"
  chmod +x "${_outfile}"
}


setup_venv() {
  local _system_py3
  _system_py3=$( which python3 )

  [[ -x "${_system_py3}" ]] || die "python3 not found"

  "${_system_py3}" -m venv "${DS_VENV}" || die "error during make venv"

  "${DS_PY3}" -m pip install --upgrade pip

  "${DS_PY3}" -m pip install -r "${INSTALL_DIR}"/files/python_deps.txt
}


cleanup() {
  # be explicit when deleting things
  local _files
  _files=( go.mod go.sum lap.go lap README )
  [[ -d "${LAP_DIR}" ]] && {
    for f in "${_files[@]}"; do
      fn="${LAP_DIR}"/"${f}"
      [[ -f "${fn}" ]] && rm -f "${fn}"
    done
    rmdir "${LAP_DIR}"
  }
  rm -rf "${TMP_DIR}"
}


###
# MAIN
###

install_go

install_lap

install_jq

setup_venv

cleanup
