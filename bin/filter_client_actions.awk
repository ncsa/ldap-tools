function ip2host( ip ) {
  # looks up hostname, returns string of "IP,HOSTNAME"
  cmd = "getent hosts " ip
  #printf( "command is %s\n", cmd )
  cmd | getline ip_n_hostname
  rc = close( cmd )
  if ( length(ip_n_hostname) < length(ip) ) {
    ip_n_hostname = ip ",?"
  }
  sub( / +/, ",", ip_n_hostname )
  return ip_n_hostname
}

function print_csv_row( qty, action, ip_host ) {
  printf "%s,%s,%s\n", qty, action, ip_host
}

BEGIN {
  print_csv_row( "qty", "action", "ip,hostname" )
}

# skip empty lines
$1 != "client" {next}

# skip BIND and UNBIND
$4 == "BIND"   {next}
$4 == "UNBIND" {next}

# a valid line starts with "client" and has 5 fields
# Sample line...
#       client     141.142.161.5     action     SRCH        2
#       $1         $2                $3         $4          $5
#                  CLIENT-IP                    ACTION      QTY
$1 == "client" && NF == 5 {
  retval = ip2host($2)
  print_csv_row( $5, $4, retval )
}
