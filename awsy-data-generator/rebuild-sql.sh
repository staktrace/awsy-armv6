#!/usr/bin/env bash

USAGE="$0 <data-folder> <pid>"
FOLDER=${1?$USAGE}
PID=${2?$USAGE}

if [ -f "$FOLDER/awsy.sql.gz" ]; then
    exit 0;
fi

echo "Processing data in $FOLDER"

pushd $FOLDER >/dev/null
if [ ! -f "pushlog.json" ]; then
    HGURL=$(tail -1 fennec-*-armv6.txt)
    PUSHURL=${HGURL/rev\//json-pushes?changeset=}
    curl $PUSHURL > pushlog.json 2>/dev/null
fi

PUSHTIME=$(cat pushlog.json | grep "date" | tr -d -c '0123456789')
FULLCSET=$(cat pushlog.json | grep -A 1 "changesets" | tail -1 | tr -d -c '0123456789abcdefABCDEF')
TESTTIME=$(stat -c %Y memory-report-TabsClosedForceGC-$PID.json.gz)
TESTNAME="Android-ARMv6"

printf 'REPLACE INTO `benchtester_builds` (`name`, `time`) VALUES ("%s", "%s");\n' $FULLCSET $PUSHTIME > awsy.sql
printf 'INSERT INTO `benchtester_tests` (`name`, `time`, `build_id`, `successful`) SELECT "%s", "%s", `id`, "%s" FROM benchtester_builds WHERE `name`="%s" LIMIT 1;\n' \
        "$TESTNAME" "$TESTTIME" "1" "$FULLCSET" >> awsy.sql

TMPFILE=$(mktemp)
PATHS=$(mktemp)
NEWPATH=$(mktemp)
for i in Start StartSettled TabsOpen TabsOpenSettled TabsOpenForceGC TabsClosed TabsClosedSettled TabsClosedForceGC; do
    zcat memory-report-$i-$PID.json.gz > $TMPFILE
    COUNT=$(grep "path" $TMPFILE | wc -l)
    (   for ((j = 0; j < $COUNT; j++)); do
            echo "reports/$j/path"
            echo "reports/$j/amount"
        done
    ) |
    xargs java -cp ../../awsy-data-generator/sts_util.jar com.staktrace.util.conv.json.Extractor -object $TMPFILE |
    while read -r LABEL && read -r VALUE; do
        LABEL=${LABEL//\"/\"\"}
        LABEL="Iteration 1/$i/$LABEL"
        echo "$LABEL" > $NEWPATH
        grep -Fxf "$NEWPATH" "$PATHS" >/dev/null
        if [ $? -eq 0 ]; then
            printf 'UPDATE `benchtester_data` SET `value`=`value`+"%s" WHERE `datapoint`="%s" AND `test_id`=(SELECT `id` FROM `benchtester_tests` WHERE `name`="%s" AND `time`="%s");\n' \
                "$VALUE" "$LABEL" "$TESTNAME" "$TESTTIME" >> awsy.sql
        else
            cat $NEWPATH >> $PATHS
            printf 'INSERT INTO `benchtester_data` (`test_id`, `datapoint`, `value`) SELECT `id`, "%s", "%s" FROM `benchtester_tests` WHERE `name`="%s" AND `time`="%s";\n' \
                "$LABEL" "$VALUE" "$TESTNAME" "$TESTTIME" >> awsy.sql
        fi
    done
done
rm $TMPFILE
rm $NEWPATH
rm $PATHS

gzip awsy.sql
popd >/dev/null
