#!/usr/bin/env bash

ROOT=$HOME/awsy-armv6
SRC=$HOME/zspace/mozilla-armv6
export ANDROID_SERIAL=B7510361ef029

pushd $SRC

echo "Syncing and building..."
rm obj-android/dist/fennec-*-armv6.*
(git fetch origin \
    && git rebase origin/inbound \
    && make -f client.mk \
    && pushd obj-android \
    && make package \
    && popd) 2>&1 | tee obj-android/build.log

STAMP=$(date +%Y%m%d%H%M%S)
CSET=$(git log -1 --oneline | cut -d " " -f 1)
DIR=$ROOT/data/$STAMP-$CSET

echo "Processing to directory $DIR..."

mkdir -p $DIR
cp obj-android/build.log $DIR

ls obj-android/dist/fennec-*-armv6.apk
if [ $? -eq 0 ]; then
    cp obj-android/dist/fennec-*-armv6.apk $DIR/
    pushd $DIR
    echo "Setting up device with Fennec..."
    adb uninstall org.mozilla.fennec_$USER
    adb shell dumpsys > dumpsys-start.log
    adb logcat -c
    adb install *.apk
    $ROOT/run-awsy-test.sh &
    PID=$!
    while true; do
        sleep 10;
        grep "AWSY-ARMV6-DONE" device.log
        if [ $? -eq 0 ]; then
            echo "Successful end of test marker found!"
            break
        fi
        grep "Process org.mozilla.fennec_$USER .* has died" device.log
        if [ $? -eq 0 ]; then
            echo "Fennec appears to have died before the test completed!"
            break
        fi
    done
    echo "Shutting down..."
    kill $PID
    sleep 5
    adb shell dumpsys > dumpsys-end.log
    popd
else
    echo "Unable to find APK file; check $DIR/build.log for errors"
fi

echo "All done!"

popd
