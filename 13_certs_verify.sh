# See also:
# https://docs.redhat.com/en/documentation/red_hat_directory_server/12/pdf/securing_red_hat_directory_server/Red_Hat_Directory_Server-12-Securing_Red_Hat_Directory_Server-en-US.pdf

# INSTANCE_NAME=ncsa-test-ldap
# HOST=$( hostname -f )
# LETSENCRYPT_BASE=/etc/letsencrypt
# CERT_DIR="${LETSENCRYPT_BASE}"/live/"${HOST}"
# HOST_KEY="${CERT_DIR}"/privkey.pem
# HOST_CERT="${CERT_DIR}"/cert.pem
# CA_CERT="${CERT_DIR}"/chain.pem
# CA_NAME="LetsEncrypt CA"
# NICKNAME='Server-Cert'

. ds_lib.sh

set -x

get_base() {
  _ldapsearch \
    -x \
    -s \
    base
}


get_config() {
  _ldapsearch \
    -LLx \
    -b "cn=config"
}


get_replication() {
  _ldapsearch \
    -LLx \
    -b "cn=mapping tree,cn=config"
}


###
# MAIN
###

get_base

get_config

#get_replication
