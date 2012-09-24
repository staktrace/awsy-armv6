#!/usr/bin/env bash

BUILD=$(./pick-build.sh)
if [ $? -eq 0 ]; then
    ./run-build.sh $BUILD
fi
