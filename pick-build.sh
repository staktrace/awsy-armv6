#!/usr/bin/env bash

export MATCHED=0
BUILDID=$(links -dump $STAGE/ | grep ' \[DIR\] ' | awk '{ print $2 }' | sed -e "s#/##" | sort -n |
    while read buildstamp; do
        if [[ -d $ROOT/$buildstamp ]]; then
            MATCHED=1
        elif [[ $MATCHED -eq 1 ]]; then
            echo $buildstamp
            exit
        else
            echo $buildstamp
        fi
    done |
    tail -n 1)

if [[ -n $BUILDID ]]; then
    echo "$BUILDID"
    exit 0
fi

exit 1
