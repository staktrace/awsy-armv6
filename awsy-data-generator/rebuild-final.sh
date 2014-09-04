#!/usr/bin/env bash

USAGE="$0 <data-folder> <pid>"
FOLDER=${1?$USAGE}
PID=${2?$USAGE}

if [ -f "$FOLDER/awsy.final.gz" ]; then
    exit 0;
fi

echo "Processing data in $FOLDER"

pushd $FOLDER >/dev/null
if [ ! -f "pushlog.json" ]; then
    HGURL=$(tail -1 fennec-*-arm.txt)
    PUSHURL=${HGURL/rev\//json-pushes?changeset=}
    curl $PUSHURL > pushlog.json 2>/dev/null
fi

PUSHTIME=$(cat pushlog.json | grep "date" | tr -d -c '0123456789')
FULLCSET=$(cat pushlog.json | grep -B 1 "]" | head -1 | tr -d -c '0123456789abcdefABCDEF')
TESTTIME=$(stat -c %Y *memory-report-TabsClosedForceGC-$PID.json.gz)
TESTNAME="Android-ARM"

if [ -z "$PUSHTIME" -o -z "$FULLCSET" ]; then
    echo "Error! Unable to extract PUSHTIME or FULLCSET from pushlog.json!"
    exit 1
fi

printf 'buildname\n%s\nbuildtime\n%s\ntestname\n%s\ntesttime\n%s\n' "$FULLCSET" "$PUSHTIME" "$TESTNAME" "$TESTTIME" > awsy.final

for i in Start StartSettled TabsOpen TabsOpenSettled TabsOpenForceGC TabsClosed TabsClosedSettled TabsClosedForceGC; do
    zcat *memory-report-$i-$PID.json.gz | java -cp ../../../awsy-data-generator:../../../awsy-data-generator/sts_util.jar Dumper "Iteration 1/$i/" >> awsy.final
done

gzip awsy.final
popd >/dev/null
