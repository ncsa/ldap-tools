#!/usr/bin/awk -f

BEGIN {
  INSTALL_DIR = "/root/ldap-tools"
  JQ = INSTALL_DIR "/bin/jq"
  LOGDIRBASE = "/var/log/dirsrv"
  outfn = ""
  logdir = ""
}


function get_logdir() {
  cmd = "find " LOGDIRBASE " -mindepth 1 -maxdepth 1 -type d -name 'slap*' | head -1"
  cmd | getline logdir
  close(cmd)
}


function mk_outfn( json ) {
  cmd = JQ " -r 'include \"datetimeutils\"; ldap_date_as_digits(.time[:11])'"
  print |& cmd
  close( cmd, "to" )
  cmd |& getline year_mo_dy
  close(cmd)
  if ( logdir == "" ) {
    get_logdir()
  }
  return logdir "/" year_mo_dy "_access.json"
}


{
  new_outfn = mk_outfn( $0 )
  if ( new_outfn != outfn ) {
    close( outfn )
    outfn = new_outfn
  }
  print >>outfn
}
