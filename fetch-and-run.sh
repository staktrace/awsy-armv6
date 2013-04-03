#!/usr/bin/env bash

BUILDID=${1?"Usage: $0 <build-id>"}

BUILD=$(./fetch-build.sh $BUILDID)
if [ $? -eq 0 ]; then
    for ((i = 1; i <= 5; i++)); do
        ./run-build.sh $BUILD
        RESULT=$?
        if [ $RESULT -eq 0 ]; then
            rm $BUILD/fennec-*-armv6.apk
            if [ $UPLOAD_AWSY_RESULTS -eq 1 ]; then
                pushd awsy-data-generator >/dev/null
                ./upload.sh $BUILD
                popd >/dev/null
            fi
            exit 0;
        fi
        echo "Running the build at $BUILD failed; saving logs to $BUILD/failed-$i"
        mkdir -p $BUILD/failed-$i
        mv $BUILD/*.log $BUILD/*.gz $BUILD/failed-$i
        if [ $RESULT -eq 2 ]; then
            # unable to recover from reboot
            exit $RESULT
        fi
        echo "Trying again..."
        sleep 5
    done
    echo "Unable to run the build $BUILD successfully after 5 attempts; giving up!"
    rm $BUILD/fennec-*-armv6.apk
    exit 1
else
    echo "Specified build could not be found"
    exit 1
fi
