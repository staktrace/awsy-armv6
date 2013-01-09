#!/usr/bin/env bash
rm *.graphdata
for i in ../data/*; do
    ./rebuild-one.sh $i
    if [ $? -eq 1 ]; then
        continue
    fi
    cat $i/memory-summary.json |
    for j in Start StartSettled TabsOpen TabsOpenSettled TabsOpenForceGC TabsClosed TabsClosedSettled TabsClosedForceGC; do
        read resident
        echo "      [ \"$TIMESTAMP\", $resident, \"$HGCSET\" ]," >> resident-$j.graphdata
        read explicit
        echo "      [ \"$TIMESTAMP\", $explicit, \"$HGCSET\" ]," >> explicit-$j.graphdata
    done
done
for i in resident explicit; do
    echo "[" >> $i.graphdata
    for j in Start StartSettled TabsOpen TabsOpenSettled TabsOpenForceGC TabsClosed TabsClosedSettled TabsClosedForceGC; do
        echo "  {" >> $i.graphdata
        echo "    \"label\": \"$j\"," >> $i.graphdata
        echo "    \"data\": [" >> $i.graphdata
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
