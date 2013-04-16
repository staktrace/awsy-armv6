#!/usr/bin/env bash
USAGE="[SHOWFOLDER=1] $0 <start-folder> <graph-line>"
START=${1?$USAGE}
LINE=${2?$USAGE}
COUNT=${COUNT:-40}

for i in $(ls | grep -A $COUNT $START); do
    if [ -f $i/awsy.final.gz ]; then
        if [[ -n "$SHOWFOLDER" && $SHOWFOLDER -eq 1 ]]; then
            echo -n "$i "
        fi
        tail -n 1 $i/*.txt | sed -e "s/.*rev.//" | xargs echo -n
        zgrep 'resident"' $i/memory-report-$LINE-*.gz | awk -F, '{ print $5 }' | sed -e 's/.amount.//'
    fi
done
