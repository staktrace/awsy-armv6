#!/usr/bin/env bash

while true; do
    ./main.sh
    if [ $? -eq 2 ]; then
        sleep 300;
    fi
done

