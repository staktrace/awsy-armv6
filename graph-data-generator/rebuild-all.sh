#!/usr/bin/env bash
rm *.graphdata
for i in ../data/*; do
    PID=$(ls $i/memory-report-TabsClosedForceGC-*.json.gz)
    if [ $? -ne 0 ]; then
        echo "Missing data in $i" > /dev/stderr
        continue
    fi
    PID=${PID%%.*}
    PID=${PID##*-}
    TIMESTAMP=$(head -1 $i/fennec-*-armv6.txt)
    for j in Start StartSettled TabsOpen TabsOpenSettled TabsOpenForceGC TabsClosed TabsClosedSettled TabsClosedForceGC; do
        zcat $i/memory-report-$j-$PID.jzon.gz | java -cp sts_util.jar com.staktrace.util.conv.json.Extractor -object - reports/path=resident/amount reports/path=explicit/amount |
        while read resident explicit; do
            echo "[ $TIMESTAMP, $resident ]" >> resident-$j.graphdata
            echo "[ $TIMESTAMP, $explicit ]" >> explicit-$j.graphdata
        done
    done
done
for i in resident explicit; do
    echo "[" >> $i.graphdata
    for j in Start StartSettled TabsOpen TabsOpenSettled TabsOpenForceGC TabsClosed TabsClosedSettled TabsClosedForceGC; do
        cat $i-$j.graphdata >> $i.graphdata
    done
    echo "]" >> $i.graphdata
done
