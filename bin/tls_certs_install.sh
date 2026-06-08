#!/usr/bin/bash

# See also:
# https://docs.redhat.com/en/documentation/red_hat_directory_server/12/html-single/securing_red_hat_directory_server/index#proc_renewing-a-tls-certificate-using-the-command-line_assembly_renewing-a-tls-certificate

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/ds_lib.sh


get_filename() {
  local -n _varname
  _varname="${1}"
  local _prompt
  _prompt="${2}"
  [[ -z "${_prompt}" ]] && die 'missing prompt'
  read -p "${_prompt} ['q' to quit'] " response
  if [[ "${#response}" -gt 0 ]] ; then
    if [[ "${response}" == 'q' ]] ; then
      die 'forced quit'
    elif [[ -f "${response}" ]] ; then
      _varname="${response}"
    else
      echo "file not found: '${response}'"
    fi
  fi
}


get_subject_cn() {
  local _cert_fn
  _cert_fn="${1}"
  openssl x509 -noout -subject -nameopt multiline -in "${_cert_fn}" \
    | grep commonName \
    | sed -n 's/ *commonName *= //p'   
}


get_host_cert_filenames() {
  unset HOST_CERT HOST_KEY
  ask_yes_no "Install Host cert and Key ?" && {
    for varname in HOST_CERT HOST_KEY ; do
      while [[ -z "${!varname}" ]]; do
        get_filename "${varname}" "Path to ${varname}"
      done
    done
  }
  #return true if CERT and KEY both have data
  [[ -n "${HOST_CERT}"  && -n "${HOST_KEY}" ]]
}


get_ca_filenames() {
  unset CA_CERTS CA_NAMES
  echo "Add one or more CA certs?"
  select choice in "Add CA file" "Done"; do
    case "${choice}" in
      "Add CA file")
        unset TMP
        get_filename TMP "CA filename?"
        if [[ -n "${TMP}" ]] ; then
          CA_CERTS+=( "${TMP}" )
          CA_NAMES+=( "$( get_subject_cn ${TMP} )" )
        fi
        ;;
      "Done")
        break
        ;;
    esac
    echo "Add another? (press Enter to see choices again)"
  done
  [[ -n "${CA_CERTS}" ]] #return true if CA_CERTS has data
}


# If you created the private key using an external utility,
# import the server certificate and the private key:
install_cert_and_key() {
  echo "About to install ..."
  echo "HOST_CERT: ${HOST_CERT}"
  echo "HOST_KEY: ${HOST_KEY}"
  ask_yes_no "Continue?" || return 0 #short circuit exit if user said no
  [[ $DEBUG -eq $YES ]] && set -x
  _dsctl \
    tls import-server-key-cert \
    "${HOST_CERT}" \
    "${HOST_KEY}"
}


install_ca_certs() {
  i=0
  for fn in "${CA_CERTS[@]}" ; do
    CA_CERT="${fn}"
    CA_NAME="${CA_NAMES[$i]}"
    install_ca_cert
    let "i=$i+1"
  done
}


install_ca_cert() {
  # Import the CA certificate to the NSS database:
  echo "About to install ..."
  echo "CA_CERT: ${CA_CERT}"
  echo "CA_NAME: ${CA_NAME}"
  ask_yes_no "Continue?" || return 0 #short circuit exit if user said no
  [[ $DEBUG -eq $YES ]] && set -x
  _dsconf \
    security ca-certificate add \
    --file "${CA_CERT}" \
    --name "${CA_NAME}"

  # Set the trust flags of the CA certificate:
  _dsconf \
    security ca-certificate set-trust-flags \
    "${CA_NAME}" \
    --flags "CT,,"
}


enable_certs() {
  "${INSTALL_DIR}"/bin/13_certs_enable.sh
}


###
# MAIN
###

get_host_cert_filenames \
&& install_cert_and_key

get_ca_filenames \
&& install_ca_certs

enable_certs
