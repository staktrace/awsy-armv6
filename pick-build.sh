#!/usr/bin/env bash

export PICKLAST=1
export BUILDID=
BUILDID=$(links -dump $STAGE/ | grep ' \[DIR\] ' | awk '{ print $2 }' | sed -e "s#/##" | sort -n |
    while read buildstamp; do
        if [[ -d $ROOT/$buildstamp ]]; then
            BUILDID=
            PICKLAST=0
        elif [[ -z $BUILDID || $PICKLAST -eq 1 ]]; then
            BUILDID=$buildstamp
        fi
        echo "$BUILDID"
    done |
    tail -n 1)

if [[ -n $BUILDID ]]; then
    echo "$BUILDID"
    exit 0
fi

exit 1
