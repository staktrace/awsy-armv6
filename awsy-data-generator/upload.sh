#!/usr/bin/env bash

BUILD=${1?"Usage: $0 <folder>"}

PID=$(ls $BUILD/memory-report-TabsClosedForceGC-*.json.gz 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: did not find complete dataset in $BUILD"
    exit $?
fi

PID=${PID##*-}
PID=${PID%%.*}
./rebuild-final.sh $BUILD $PID
if [ $? -ne 0 ]; then
    exit $?
fi
BUILDFOLDER=${BUILD##*/}
pushd $BUILD >/dev/null
echo -n "Uploading $BUILDFOLDER to arcus... "
cp awsy.final.gz $BUILDFOLDER.gz && scp $BUILDFOLDER.gz johns@arcus:/media/awsy/mobile && rm $BUILDFOLDER.gz && echo "Success!"
popd >/dev/null
