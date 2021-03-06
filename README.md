Part 1: SETUP
=============

Nginx/TP5 setup:
----------------

    mkdir $HOME/nginx/
    pushd $HOME/nginx/
    wget http://nginx.org/download/nginx-1.5.5.tar.gz
    tar xzf nginx-1.5.5.tar.gz
    cd nginx-1.5.5
    ./configure --prefix=$HOME/nginx/install
    make
    make install
    cd ../install/conf
    vim nginx.conf # edit the "listen 80;" to be "listen 8001; listen 8002; ... listen 8100;"
    cd ../html/
    wget http://build.mozilla.org/talos/zips/tp5.zip    # or http://people.mozilla.org/~jmaher/taloszips/zips/tp5n.zip, but then mv tp5n to tp5 after unzipping
    unzip tp5.zip
    cd ../sbin
    ./nginx
    popd

Device setup:
-------------

Assumptions:
* you have cloned https://github.com/staktrace/awsy-armv6 to $HOME/awsy-armv6. If this is not the case, update $ROOT in pick-build.sh and run-build.sh
* your android SDK platform-tools folder is at $HOME/android/sdk/platform-tools. If this is not the case, update $SDK_TOOLS in build.sh
* your android device has a serial number of 01466E640801401C. If this is not the case, update $ANDROID_SERIAL in run-build.sh
* your android device is rooted such that "su" gets you a root shell, and busybox is installed and accessible from the root shell. If this is not the case, make it so.
* you have javac (>= 1.6), jar, zip, links, wget, curl, and adb on your $PATH. If not, add them.

Once the above assumptions are satisified, enter the awsy-armv6 folder and run:

    ./build.sh
    adb push forwarder/device-forwarder.jar /sdcard/
    adb push fennec-addon-awsy/awsy.xpi /sdcard/
    
    # install a clean build of org.mozilla.fennec (picking a recent build at the time of this writing, update as needed):
    adb uninstall org.mozilla.fennec
    wget http://ftp.mozilla.org/pub/mozilla.org/mobile/tinderbox-builds/mozilla-inbound-android/1409865100/fennec-35.0a1.en-US.android-arm.apk
    adb install fennec-35.0a1.en-US.android-arm.apk
    rm fennec-35.0a1.en-US.android-arm.apk

    # start fennec, and install the add-on from /sdcard/awsy.xpi (manual approval on-device needed here).
    # note that you may also get a telemetry prompt, feel free to accept that.
    adb shell am start -n org.mozilla.fennec/.App -d "file:///sdcard/awsy.xpi"
    # quit fennec QUICKLY after this (within 30 seconds, or the add-on will start loading pages and dirty your profile).

    # make a backup of the "clean" profile (everything in /data/data/org.mozilla.fennec except libs/):
    adb shell "echo 'rm /sdcard/profile.tar; cd /data/data/org.mozilla.fennec && tar cf /sdcard/profile.tar app_plugins app_plugins_private app_tmpdir cache files shared_prefs' | su"

Part 2: RUNNING
===============

    ./run-next-integration-build.sh

This will automatically do the following:
* download an appropriate build to test (if you have tested a build before, it will fetch the next untested build, otherwise it will fetch the latest inbound build; if all inbound builds are done, it will fall back to b2g-inbound and fx-team)
* install the build onto your device and reset the profile to the known clean profile created during setup
* set up the TCP port forwarding over USB from device to host
* run fennec and let the add-on load the test pages
* dump the logs into awsy-armv6/data/<buildid>
* delete the downloaded APK (to save space)
* upload the results to areweslimyet.com (assuming you can SSH to albus.mv.mozilla.com)
* re-try all of the above up to 4 additional times if for whatever reason the test fails to run to completion; data from failed runs is saved in failed-<n> subfolders in the data folder

If you want to run a pre-downloaded build, you can skip the download step and run:

    ./run-build.sh <folder>

where <folder> contains the APK that needs to be tested.
WARNING: log files and output data will be put into <folder> as well, possibly clobbering any existing log files, so back up anything you want saved before running this!

Part 3: RESULTS
===============

Log files
---------

Log files are dumped into the same folder as the APK. The following files are created:
* dumpsys-start.log, dumpsys-end.log - The output from "adb shell dumpsys" before and after the test, to provide a reasonably comprehensive description of the environment. This can mostly for diagnostic purposes, in case there are weird test results that need investigation.
* device-forwarder.log, host-forwarder.log - Log files from the forwarding setup. These can mostly be ignored, but again are provided for diagnostic purposes. Note that these often have exceptions in them due to socket closures, that is expected and normal.
* device.log - The logcat from the device while the test is running, including all the memory stats dumped.

Gotchas
=======

If you uninstall and reinstall Fennec running the setup steps, it may be that the user id for the app changes, and you should probably create a new clean profile.
