include "datetimeutils";
[inputs] | map(.time[:20]) | {start: .[0], end: .[1], duration: duration(.[1];.[0])}
