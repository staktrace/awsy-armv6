#!/usr/bin/env bash

export STAGE="http://stage.mozilla.org/pub/mozilla.org/mobile/tinderbox-builds/mozilla-inbound-android-armv6"
export STAGE_POSTFIX=""
export ROOT=$HOME/awsy-armv6/try-data
export UPLOAD_AWSY_RESULTS=0
export UPLOAD_DATA_FOLDER=0

BUILDID=${1?"Usage: $0 <inbound-build-id> [count] # inbound build id is a timestamp; count defaults to 5"}
COUNT=${2:-5}

for ((i = 0; i < $COUNT; i++)); do
    ./fetch-and-run.sh $BUILDID
    RETURN=$?
    if [ $RETURN -ne 0 ]; then
        exit $RETURN
    fi
    mv $ROOT/$BUILDID $ROOT/$BUILDID-$i
    sleep 60
done
exit 0
