BEGIN {
  INSTALL_DIR = "___INSTALL_DIR__"
  JQ = INSTALL_DIR "/bin/jq"
  LOGDIR = "/var/log/dirsrv"
  outfn = ""
  dsname = ""
}


function get_dsname() {
  cmd = "ls /var/log/dirsrv | head -1"
  cmd | getline dsname
  close(cmd)
}


function mk_outfn( json ) {
  cmd = JQ " '.time[:8]'"
  print |& cmd
  close( cmd, "to" )
  cmd |& getline year_mo_dy
  close(cmd)
  if ( dsname == "" ) {
    dsname = get_dsname()
  }
  return LOGDIR "/" dsname "/" year_mo_dy "_access.json"
}


{
  new_outfn = mk_outfn( $0 )
  if new_outfn != outfn {
    close( outfn )
    outfn = new_outfn
  }
  print >outfn
}
