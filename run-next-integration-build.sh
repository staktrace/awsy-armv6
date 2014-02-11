#!/usr/bin/env bash

for tree in mozilla-inbound fx-team; do
    export STAGE="http://stage.mozilla.org/pub/mozilla.org/mobile/tinderbox-builds/$tree-android-armv6"
    export STAGE_POSTFIX=""
    export ROOT=$HOME/awsy-armv6/data/$tree
    # currently AWSY web interface only accepts inbound data
    if [[ "$tree" == "mozilla-inbound" ]]; then
        export UPLOAD_AWSY_RESULTS=1
    else
        export UPLOAD_AWSY_RESULTS=0
    fi

    BUILDID=$(./pick-build.sh)
    if [ $? -ne 0 ]; then
        continue;
    fi

    ./fetch-and-run.sh $BUILDID
    exit $?
done
echo "No new builds found; terminating"
exit 3