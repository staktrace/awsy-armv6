#!/usr/bin/env bash

USAGE="Usage: $0 <folder-prefix-before> <folder-prefix-after>"
BEFORE=${1?$USAGE}
AFTER=${2?$USAGE}

for i in Start StartSettled TabsOpen TabsOpenSettled TabsOpenForceGC TabsClosed TabsClosedSettled TabsClosedForceGC; do
    echo $i
    echo -en "  Before\t\t"
    zgrep 'resident"' $BEFORE*/*-$i-*.gz | awk -F, '{ print $5 }' | awk -f ~/bin/stats.awk -v field=2 | grep -e "Average" -e "Stddev" | tr "\n" "\t"
    echo ""
    echo -en "  After\t\t\t"
    zgrep 'resident"' $AFTER*/*-$i-*.gz | awk -F, '{ print $5 }' | awk -f ~/bin/stats.awk -v field=2 | grep -e "Average" -e "Stddev" | tr "\n" "\t"
    echo ""
done
