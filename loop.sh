#!/usr/bin/env bash

while true; do
    ./run-next-integration-build.sh
    case $? in
        0)  # this build succeeded, keep going
            ;;
        1)  # this build failed, but keep going
            ;;
        2)  # unable to recover from reboot. abort
            exit
            ;;
        3)  # no new builds found, sleep for a bit
            sleep 300
            ;;
    esac
done

