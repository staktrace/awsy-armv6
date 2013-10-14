#!/usr/bin/env bash

BUILD=${1?"Usage: $0 <folder>"}

PID=$(ls $BUILD/memory-report-TabsClosedForceGC-*.json.gz 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: did not find complete dataset in $BUILD"
    exit $?
fi

if [ ! -f $BUILD/awsy.final.gz ]; then
    echo "Didn't find awsy.final.gz in $BUILD..."
    exit 1
fi

# test if we should re-process this file
zgrep 'heap-unclassified' $BUILD/awsy.final.gz
if [ $? -eq 0 ]; then
    echo "Found a awsy.final.gz with heap-unclassified; exiting..."
    exit 1
fi

echo "Reprocessing $BUILD..."

rm $BUILD/awsy.final.gz

PID=${PID##*-}
PID=${PID%%.*}
./rebuild-final.sh $BUILD $PID
if [ $? -ne 0 ]; then
    exit $?
fi
BUILDFOLDER=${BUILD##*/}
pushd $BUILD >/dev/null
echo -n "Uploading $BUILDFOLDER to arcus..."
echo "mode" > $BUILDFOLDER
echo "replace" >> $BUILDFOLDER
zcat awsy.final.gz >> $BUILDFOLDER
gzip $BUILDFOLDER && scp $BUILDFOLDER.gz johns@arcus:/media/awsy/mobile && rm $BUILDFOLDER.gz && echo "Success!"
popd >/dev/null
