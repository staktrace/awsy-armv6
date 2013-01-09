#!/usr/bin/env bash

DIR=${1?"Usage: $0 <build-dir>"}

PID=$(ls $DIR/memory-report-TabsClosedForceGC-*.json.gz 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Missing data in $DIR" > /dev/stderr
    exit 1
fi
PID=${PID##*-}
PID=${PID%%.*}
if [ ! -f "$DIR/memory-summary.json" ]; then
    for j in Start StartSettled TabsOpen TabsOpenSettled TabsOpenForceGC TabsClosed TabsClosedSettled TabsClosedForceGC; do
        zcat $DIR/memory-report-$j-$PID.json.gz | java -cp sts_util.jar com.staktrace.util.conv.json.Extractor -object - reports/path=resident/amount reports/path=explicit/amount >> $DIR/memory-summary.json
    done
fi
exit 0
