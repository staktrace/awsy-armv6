#!/usr/bin/env bash
USAGE="[SHOWFOLDER=1] $0 <start-folder> <graph-line>"
START=${1?$USAGE}
LINE=${2?$USAGE}
COUNT=${COUNT:-40}

for i in $(ls | grep -A 40 $START); do
    if [ -f $i/awsy.final.gz ]; then
        if [[ -n "$SHOWFOLDER" && $SHOWFOLDER -eq 1 ]]; then
            echo -n "$i "
        fi
        tail -n 1 $i/*.txt | sed -e "s/.*rev.//" | xargs echo -n
        echo -n " : "
        zgrep -A 1 "$LINE/explicit$" $i/awsy.final.gz | tail -n 1
    fi
done
