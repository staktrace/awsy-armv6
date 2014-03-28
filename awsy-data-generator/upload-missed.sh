#!/usr/bin/env bash

if [ ! -d ../data/mozilla-inbound ]; then
    echo "Run this from the awsy-data-generator folder!"
    exit 1;
fi

pushd ../data/mozilla-inbound
for i in *; do
    if [ -f $i/$i.gz ]; then
        pushd $i && scp $i.gz arcus:/media/awsy/mobile && rm $i.gz
        popd
    fi
done
