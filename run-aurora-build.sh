#!/usr/bin/env bash

DIR=${1?"Usage: $0 <build-folder>"}

echo "Running test build at $DIR/"
pushd $DIR >/dev/null

export ROOT=$HOME/awsy-armv6
export ANDROID_SERIAL=B7510361ef029

FAILED=1
ls fennec-*-armv6.apk
if [ $? -eq 0 ]; then
    echo "Setting up device with Fennec..."
    adb shell dumpsys > dumpsys-start.log
    adb logcat -c
    adb forward tcp:8000 tcp:8000
    adb uninstall org.mozilla.fennec_aurora
    adb install *.apk
    adb shell "echo 'cd /data/data/org.mozilla.fennec_aurora && busybox tar xzf /sdcard/profile.tgz' | su"
    echo "Setting up port forwarding..."
    adb shell "echo 'dalvikvm -cp /sdcard/device-forwarder.jar Main -device 8000 25' | su" > device-forwarder.log 2>&1 &
    sleep 1
    java -cp $ROOT/forwarder/host-forwarder.jar Main -host 8000 25 > host-forwarder.log 2>&1 &
    PID_FORWARDER=$!
    sleep 5
    echo "Starting fennec and running test..."
    adb shell am start -n org.mozilla.fennec_aurora/.App
    adb logcat -v time > device.log &
    PID_LOGCAT=$!
    while true; do
        sleep 10;
        grep "AWSY-ARMV6-DONE" device.log
        if [ $? -eq 0 ]; then
            FAILED=0
            echo "Successful end of test marker found!"
            break
        fi
        grep "Process org.mozilla.fennec_aurora .* has died" device.log
        if [ $? -eq 0 ]; then
            echo "Fennec appears to have died before the test completed!"
            break
        fi
        grep "Entered the Android system server" device.log
        if [ $? -eq 0 ]; then
            echo "The device may have rebooted during test!"
            break;
        fi
    done
    echo "Shutting down..."
    adb shell "echo 'busybox pkill org.mozilla.fennec_aurora' | su"
    sleep 2
    kill $PID_FORWARDER
    kill $PID_LOGCAT
    sleep 2
    adb shell dumpsys > dumpsys-end.log
    adb pull /data/data/org.mozilla.fennec_aurora/app_tmp/
    adb shell "rm /data/data/org.mozilla.fennec_aurora/app_tmp/*"
else
    echo "Unable to find APK file; check $DIR/ for errors"
fi

echo "All done!"

popd >/dev/null

exit $FAILED
