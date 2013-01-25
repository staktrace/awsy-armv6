#!/usr/bin/env bash
for i in ../data/*; do
    PID=$(ls $i/memory-report-TabsClosedForceGC-*.json.gz)
    if [ $? -ne 0 ]; then
        echo "Missing data in $i"
        continue
    fi
    PID=${PID##*-}
    PID=${PID%%.*}
    ./rebuild-final.sh $i $PID
done
