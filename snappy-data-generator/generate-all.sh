#!/usr/bin/env bash

for i in ../data/mozilla-inbound/*; do
    if [ -f $i/awsy.final.gz ]; then
        grep zerdatime $i/device.log | head -3 | awk -v build=$(tail -1 $i/fennec-*.txt) -f time.awk
    fi
done
