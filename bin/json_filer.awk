#!/usr/bin/awk -f

BEGIN {
  INSTALL_DIR = "___INSTALL_DIR___"
  JQ = INSTALL_DIR "/bin/jq"
  outfn = ""
  curdate = ""
  # logdir    - passed in on cmdline
  # startdate - passed in on cmdline
  # enddate   - passed in on cmdline
  
  # send_to_syslog - (OPTIONAL)
  #     If present, send json to syslog, in addition to the local file
  #     Must have value of "Y" for sending to syslog
  if ( (send_to_syslog=="") && (send_to_syslog==0) ) {
    send_to_syslog = 0
  }

  # verbose - (OPTIONAL)
  #     If present, print informational output
  #     Must be set to "Y" for activation
  if ( (verbose=="") && (verbose==0) ) {
    verbose = 0
  }
}


function notify( msg ) {
  if (verbose=="Y") {
    print msg
  }
}


function json2date( json ) {
  cmd = JQ " -Rr 'include \"datetimeutils\"; fromjson? | ldap_date_as_digits(.time[:11])'"
  print json |& cmd
  close( cmd, "to" )
  cmd |& getline year_mo_dy
  close(cmd)
  return year_mo_dy
}


function mk_outfn( date ) {
  return logdir "/" date "_access.json"
}


function file2syslog( filename ) {
  syslogcmd = "logger --tag ldap-access-parser --size 4096 --file " filename
  if ( length( filename ) > 1 ) {
    if (send_to_syslog=="Y") {
      notify( sprintf( "About to run syslog cmd '%s'", syslogcmd ) )
      rv = system( syslogcmd )
      if ( rv != 0 ) {
        printf "ERROR: syslog cmd '%s' failed with exit code '%s\n", syslogcmd, rv
      }
    }
    else {
      notify( sprintf( "Not running syslog cmd '%s'", syslogcmd ) )
    }
  }
}


# skip irrelevant lines (if input is coming from syslog)
#!/ ldap_access_parser: / { next }

# process ldap json lines
{
  # split( $0, parts, " ldap_access_parser: " )
  # json_line = parts[2]
  json_line = $0
  newdate = json2date( json_line )
  if ( length(newdate) != 8 ) {
    printf "Bad date for json '%s'\n", json_line
    next
  }
  else if ( newdate < startdate ) {
    next
  }
  else if ( newdate >= enddate ) {
    next
  }
  else {
    if ( newdate != curdate ) {
      curdate = newdate
      new_outfn = mk_outfn( newdate )
      # add new file to syslog list
      syslog_files[new_outfn] = 1
      # close old file
      close( outfn )
      # send old file to syslog
      file2syslog( outfn )
      # remove old file from list for syslog
      delete syslog_files[outfn]
      # set new file as output
      outfn = new_outfn
      notify( sprintf( "Created '%s'", outfn ) )
    }
    # write json to output file
    # single redirect '>' will overwrite existing file for the first write
    # but because awk keeps the file handle open, subsequent writes will append
    print json_line >outfn
  }
}

END {
  for ( filename in syslog_files ) {
    file2syslog( filename )
  }
}
