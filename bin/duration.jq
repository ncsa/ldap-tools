def duration($finish; $start):
  def twodigits: "00" + tostring | .[-2:];
  [$finish, $start]
  | map(strptime("%d/%b/%Y:%H:%M:%S") | mktime) # seconds
  | .[0] - .[1]
  | (. % 60 | twodigits) as $s
  | (((. / 60) % 60) | twodigits)  as $m
  | (./3600 | floor) as $h
  | "\($h):\($m):\($s)" ;

[inputs] | map(.time[:20]) | {start: .[0], end: .[1], duration: duration(.[1];.[0])}
