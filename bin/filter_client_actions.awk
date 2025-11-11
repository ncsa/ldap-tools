function ip2host( ip ) {
  cmd = "getent hosts " ip
  #printf( "command is %s\n", cmd )
  cmd | getline ip_n_hostname
  rc = close( cmd )
  if ( rc != 0 ) {
    exit "Non-zero exit during '" cmd "'"
  }
  return ip_n_hostname
}

# skip empty lines
$1 != "client" {next}

# skip BIND and UNBIND
$4 == "BIND"   {next}
$4 == "UNBIND" {next}

# a valid line starts with "client" and has 5 fields
# Sample line...
#       client     141.142.161.5     action     RESULT      2
#       $1         $2                $3         $4          $5
#                  CLIENT-IP                    ACTION      QTY
$1 == "client" && NF == 5 {
  #print
  retval = ip2host($2)
  #printf "%s\n", retval
  printf "%6d %7s %s\n", $5, $4, retval
}
