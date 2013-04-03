#!/usr/bin/env bash

export STAGE="http://stage.mozilla.org/pub/mozilla.org/firefox/try-builds"
export STAGE_POSTFIX="try-android-armv6/"
export ROOT=$HOME/awsy-armv6/try-data
export UPLOAD_AWSY_RESULTS=0

BUILDID=${1?"Usage: $0 <try-build-id> # try build id is in form of user@host.tld-csethash"}

./fetch-and-run.sh $BUILDID
exit $?
