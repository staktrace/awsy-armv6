#!/usr/bin/env bash
for i in ../data/*; do
    PID=$(ls $i/memory-report-TabsClosedForceGC-*.json.gz)
    if [ $? -ne 0 ]; then
        echo "Missing data in $i"
        continue
    fi
    if [ -f $i/awsy.sql ]; then
        continue
    fi
    PID=${PID##*-}
    PID=${PID%%.*}
    echo "Processing data in $i"
    ./rebuild-sql.sh $i $PID
done
