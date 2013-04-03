#!/usr/bin/env bash

export STAGE="http://stage.mozilla.org/pub/mozilla.org/mobile/tinderbox-builds/mozilla-inbound-android-armv6"
export STAGE_POSTFIX=""
export ROOT=$HOME/awsy-armv6/data
export UPLOAD_AWSY_RESULTS=1

BUILDID=$(./pick-build.sh)
if [ $? -ne 0 ]; then
    echo "No new builds found; terminating"
    exit 3
fi

./fetch-and-run.sh $BUILDID
exit $?
