#!/usr/bin/env bash
rm *.graphdata
for i in ../data/*; do
    PID=$(ls $i/memory-report-TabsClosedForceGC-*.json.gz)
    if [ $? -ne 0 ]; then
        echo "Missing data in $i" > /dev/stderr
        continue
    fi
    PID=${PID##*-}
    PID=${PID%%.*}
    TIMESTAMP=$(head -1 $i/fennec-*-armv6.txt)
    for j in Start StartSettled TabsOpen TabsOpenSettled TabsOpenForceGC TabsClosed TabsClosedSettled TabsClosedForceGC; do
        zcat $i/memory-report-$j-$PID.json.gz | java -cp sts_util.jar com.staktrace.util.conv.json.Extractor -object - reports/path=resident/amount reports/path=explicit/amount |
        while read resident; do
            echo "      [ $TIMESTAMP, $resident ]," >> resident-$j.graphdata
            read explicit;
            echo "      [ $TIMESTAMP, $explicit ]," >> explicit-$j.graphdata
        done
    done
done
for i in resident explicit; do
    echo "[" >> $i.graphdata
    for j in Start StartSettled TabsOpen TabsOpenSettled TabsOpenForceGC TabsClosed TabsClosedSettled TabsClosedForceGC; do
        echo "  {" >> $i.graphdata
        echo '    "label": "' $j '",' >> $i.graphdata
        echo '    "data": [' >> $i.graphdata
        cat $i-$j.graphdata >> $i.graphdata
        rm $i-$j.graphdata
        echo "      null" >> $i.graphdata
        echo "    ]" >> $i.graphdata
        if [ $j == "TabsClosedForceGC" ]; then
            echo "  }" >> $i.graphdata
        else
            echo "  }," >> $i.graphdata
        fi
    done
    echo "]" >> $i.graphdata
done
