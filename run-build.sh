#!/usr/bin/env bash

DIR=${1?"Usage: $0 <build-folder>"}
pushd $DIR

export ROOT=$HOME/awsy-armv6
export ANDROID_SERIAL=B7510361ef029

ls fennec-*-armv6.apk
if [ $? -eq 0 ]; then
    echo "Setting up device with Fennec..."
    adb shell dumpsys > dumpsys-start.log
    adb logcat -c
    adb forward tcp:8000 tcp:8000
    adb install -r *.apk
    adb shell "echo 'cd /data/data/org.mozilla.fennec_$USER && rm -r * && busybox tar xzf /sdcard/profile.tgz' | su"
    echo "Setting up port forwarding..."
    adb shell "echo 'dalvikvm -cp /sdcard/device-forwarder.jar Main -device 8000' | su" &
    sleep 1
    java -cp $ROOT/forwarder/host-forwarder.jar Main -host 8000 25 &
    PID_FORWARDER=$!
    echo "Starting fennec..."
    adb am start -n org.mozilla.fennec
    adb logcat -v time > tee device.log &
    PID_LOGCAT=$!
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
    kill $PID_FORWARDER
    kill $PID_LOGCAT
    sleep 5
    adb shell dumpsys > dumpsys-end.log
    popd
else
    echo "Unable to find APK file; check $DIR/ for errors"
fi

echo "All done!"

popd
