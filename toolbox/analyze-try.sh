#!/usr/bin/env bash

FOLDER=${1?"Usage: $0 <folder-prefix>"}

echo "Resident memory from StartSettled data files for $FOLDER*:"
zgrep 'resident"' $FOLDER*/*StartSettled*.gz | awk -F, '{ print $5 }'

echo "Stats dropping the highest value:"
COUNT=$(zgrep 'resident"' $FOLDER*/*StartSettled*.gz | wc -l)
zgrep 'resident"' $FOLDER*/*StartSettled*.gz | awk -F, '{ print $5 }' | sort -n | head -n $((COUNT - 1)) | awk -f ~/bin/stats.awk -v field=2
