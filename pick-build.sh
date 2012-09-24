#!/usr/bin/env bash

export STAGE="http://stage.mozilla.org/pub/mozilla.org/mobile/tinderbox-builds/mozilla-inbound-android-armv6"
export ROOT=$HOME/awsy-armv6/data

export PICKLAST=1
BUILDID=$(links -dump $STAGE/ | grep ' \[DIR\] ' | awk '{ print $2 }' | sed -e "s#/##" | sort -n |
    while read buildstamp; do
        if [[ -d $ROOT/$buildstamp ]]; then
            echo ""
            PICKLAST=0
        elif [[ -z $BUILDID || $PICKLAST -eq 1 ]]; then
            echo "$buildstamp"
        fi
    done |
    tail -n 1)

if [[ -n $BUILDID ]]; then
    mkdir -p $ROOT/$BUILDID
    pushd $ROOT/$BUILDID >/dev/null 2>&1
    APK=$(links -dump $STAGE/$BUILDID/ | grep "fennec-.*-armv6.apk" | awk '{print $3}')
    wget $STAGE/$BUILDID/$APK >/dev/null 2>&1
    wget $STAGE/$BUILDID/${APK//apk/txt} >/dev/null 2>&1
    echo "$ROOT/$BUILDID"
    popd >/dev/null 2>&1
    exit 0
fi

exit 1
