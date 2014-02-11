#!/usr/bin/env bash
(for i in */device.log; do
    echo -n "$i: ";
    awk '/Start proc org.mozilla.fennec/ { start = $2 } /DONE/ { print start, ":", $2 }' $i;
done) |
awk -F: '{ s=$7-$4; m=$6-$3; h=$5-$2; if (s < 0) { s+=60; m-- }; if (m < 0) { m+=60; h-- }; if (h < 0) { h += 24 }; print $1 ": " h ":" m ":" s }'
