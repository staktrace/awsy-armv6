#!/usr/bin/env bash

echo "Attempting to recover from device reboot..."
sleep 30
echo "Attempting device unlock..."
for ((unlockAttempt = 0; unlockAttempt < 3; unlockAttempt++)); do
    adb logcat -c
    $HOME/android/sdk/tools/monkeyrunner unlock.py
    sleep 10
    adb logcat -d | grep "KeyguardViewMediator.*handleTimeout"
    if [ $? -eq 0 ]; then
        echo "Device unlock appears to have been successful"
        exit 0
    else
        echo "Device unlock may have failed. Trying again..."
    fi
done
exit 1
