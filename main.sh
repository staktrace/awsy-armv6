#!/usr/bin/env bash

BUILD=$(./pick-build.sh)
if [ $? -eq 0 ]; then
    for ((i = 1; i <= 5; i++)); do
        ./run-build.sh $BUILD
        if [ $? -eq 0 ]; then
            exit 0;
        fi
        echo "Running the build at $BUILD failed; saving logs to $BUILD/failed-$i and trying again..."
        mkdir -p $BUILD/failed-$i
        mv $BUILD/*.log $BUILD/*.gz $BUILD/failed-$i
        sleep 5
    done
    echo "Unable to run the build $BUILD successfully after 5 attempts; giving up!"
    exit 1
else
    echo "No new builds found; terminating"
    exit 2
fi
