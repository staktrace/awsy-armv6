#!/usr/bin/env bash

BUILDID=${1?"Usage: $0 <build-id>"}

if [[ -z "$STAGE" || -z "$ROOT" || -z "$STAGE_POSTFIX" ]]; then
    echo "One or more of STAGE, ROOT, and STAGE_POSTFIX were not defined." >/dev/stderr
    exit 1;
fi

if [[ -d $ROOT/$BUILDID ]]; then
    echo "Found pre-existing folder $ROOT/$BUILDID so skipping re-download..." >/dev/stderr
    echo "$ROOT/$BUILDID"
    exit 0;
fi
mkdir -p "$ROOT/$BUILDID"
pushd $ROOT/$BUILDID >/dev/null 2>&1
APK=$(links -dump $STAGE/$BUILDID/$STAGE_POSTFIX | grep "fennec-.*-armv6.apk" | awk '{print $3}')
wget $STAGE/$BUILDID/$STAGE_POSTFIX$APK >/dev/null 2>&1
wget $STAGE/$BUILDID/$STAGE_POSTFIX${APK//apk/txt} >/dev/null 2>&1
echo "$ROOT/$BUILDID"
popd >/dev/null 2>&1
exit 0

