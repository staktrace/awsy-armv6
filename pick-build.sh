#!/usr/bin/env bash

STAGE=${STAGE-"http://stage.mozilla.org/pub/mozilla.org/mobile/tinderbox-builds/mozilla-inbound-android-armv6"}
ROOT=${ROOT-"$HOME/awsy-armv6/data"}

export MATCHED=0
BUILDID=$(links -dump $STAGE/ | grep ' \[DIR\] ' | awk '{ print $2 }' | sed -e "s#/##" | sort -n |
    while read buildstamp; do
        if [[ -d $ROOT/$buildstamp ]]; then
            MATCHED=1
            echo ""
        else
            echo $buildstamp
            if [[ $MATCHED -eq 1 ]]; then
                exit
            fi
        fi
    done |
    tail -n 1)

if [[ -n $BUILDID ]]; then
    echo "$BUILDID"
    exit 0
fi

exit 1
