#!/usr/bin/env bash

COUNT=5
SLEEP_FENNEC_START=30
SLEEP_AFTER_DUMP=10
SLEEP_BETWEEN_ITERATIONS=10

adb shell "ls /sdcard/download/" | grep memory-report >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "You appear to have some memory-report files lying around in your /sdcard/download/ folder. Please remove them and try again." >/dev/stderr
    exit 1
fi

for ((i = 0; i < $COUNT; i++)); do
    echo "Running iteration $((i + 1))..."
    adb shell am start -n org.mozilla.fennec_$USER/.App
    sleep $SLEEP_FENNEC_START
    adb shell am broadcast -a org.mozilla.gecko.MEMORY_DUMP
    sleep $SLEEP_AFTER_DUMP
    adb shell ps | grep fennec_$USER | awk '{print $2}' | xargs adb shell run-as org.mozilla.fennec_$USER kill
    if [ $i -ne $((COUNT - 1)) ]; then
        sleep $SLEEP_BETWEEN_ITERATIONS
    fi
done

for i in $(adb shell ls "/sdcard/download/" | grep memory-report | tr -d '\r'); do
    (adb pull /sdcard/download/$i && adb shell "rm /sdcard/download/$i") >/dev/null 2>&1
    zgrep 'resident"' $i | awk -F, '{ print $5 }'
done |
sort -n |
head -n $((COUNT - 1)) |
awk -f ~/bin/stats.awk -v field=2
