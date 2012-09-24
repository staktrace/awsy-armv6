#!/usr/bin/env bash

BUILD=$(./pick-build.sh)
if [ $? -eq 0 ]; then
    ./run-build.sh $BUILD
else
    echo "No new builds found; terminating"
    exit 1
fi
