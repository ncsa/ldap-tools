# Install New Ldap Server
1. Create config file
   1. `00_mk_config.sh`
1. Install LDAP and dependent pkgs
   1. `01_install_ldap.sh`
1. Configure settings
   1. `02_basic_settings.sh`
   1. `03_performance_settings.sh`
1. Install NCSA custom schema
   1. `04_custom_schema.sh`
1. Build log monitoring tools
   1. `05_log_monitoring.sh`
1. Install TLS Certificates (choose only one of two options)
    1. Certs Option #1: Configure certificates via certbot
       1. `10_certs_create.sh`
       1. `11_certs_mk_hookfiles.sh`
       1. `12_certs_install.sh`
       1. `13_certs_enable.sh`
       1. `14_certs_verify.sh`
    1. Certs Option #2: Install manual certs
       1. `mkdir /root/ldap_certs`
       1. Copy the certificate, key, ca_certs into the dir above.
       1. Certificate filename must end with `.cert`
       1. Key filename must end with `.key`
       1. CA cert filenames must start with `signing_authority`
       1. `tls_certs_install.sh`
       1. NOTE: If prefer to install each part interactively:
          1. `tls_certs_install.sh --prompt`
       1. `14_certs_verify.sh`
1. Configure this ldap server as a Supplier, a Hub, or a Consumer. Do only one
   of these!
   * `20_mk_consumer.sh`
   * `20_mk_hub.sh`
   * `20_mk_supplier.sh`

### Definitions:
* Suppliers drive replication to hubs.
* Hubs receive replication and deliver it to multiple consumers.
* Consumers are the leaves, accepting replication from hubs and answering client
  requests.

## Make replication agreements
1. On a Supplier or a Hub:
   1. `repl_ctl.sh add --host <CONSUMER_HOSTNAME> --pwd <REPLICATION_PWD>`
      1. where REPLICATION_PWD is defined on the Consumer host in
         `/root/.config/ldap/<INSTANCE_NAME>/replpw`.

# Server Control
On install, the following symlinks are created:
* `restart` -> serverctl
* `start` -> serverctl
* `status` -> serverctl
* `stop` -> serverctl

Each will affect the LDAP service as named. These can be run
directly, without any cmdline parameters (they import necessary
information from the `ds_lib.sh` conf file).

# Server Interaction
* Run dsconf, dsctl, or ldapsearch commands locally as the Directory Manager
  user.
  * On install, the following symlinks are created:
    * `dsconf` -> dsc
    * `dsctl` -> dsc
    * `ldapsearch` -> dsc
  * These can be run directly and only require passing the subcommand and any
    required parameters for the subcommand. The usual "hostname", "-D
cn=Directory Manager", "-y password" are already included via `ds_lib.sh`.
  * Example: (TODO - need one or more examples)

# Install a full ldap database from backup
1. Copy a bkup file from ldap.ncsa.illinois.edu to the (new) (test) "target" server
   1. `put_v10_bkup.sh <TARGET_HOSTNAME>`
1. On the "target" host, import the database
   1.  `import_bkup.sh </path/to/ldap/db/bkup/file>`
1. Example:
   1. `[aloftus@mydesktop] ./put_v10_bkup.sh ldap105.ncsa.illinois.edu`
   1. `[root@ldap105] /root/ldap-tools/bin/import_bkup.sh
      /home/aloftus/v10bkup.ldif`

# Actuate log monitoring
TODO

# Useful commands
* Check number of entries in the LDAP database
  * `/root/ldap-tools/bin/ldapsearch -s sub -x | tail -7`
  * This is useful to validate if a new replication agreement add (or re-init)
    was successful.
* Check the LDAP base (suffix)
  * `/root/ldap-tools/bin/ldapsearch -s base -x`

# Troubleshooting
1. Run a bunch of ldapsearch's and log which ones take a "long" time, where
   "long" can be configured in the script itself and defaults to >10 seconds.
   1. `test_ldapsearch.sh`
      1. Note: Defaults to ldap-auth4. Improvement would be to accept host as
         cmdline param.
