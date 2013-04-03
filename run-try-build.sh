#!/usr/bin/env bash

export STAGE="http://stage.mozilla.org/pub/mozilla.org/firefox/try-builds"
export STAGE_POSTFIX="try-android-armv6/"
export ROOT=$HOME/awsy-armv6/try-data
export UPLOAD_AWSY_RESULTS=0

BUILDID=${1?"Usage: $0 <try-build-id> # try build id is in form of user@host.tld-csethash"}
COUNT=${2:-1}

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