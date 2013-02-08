#!/usr/bin/env bash

USAGE="$0 <before-dump-file> <after-dump-file>"
BEFORE=${1?$USAGE}
AFTER=${2?$USAGE}

BEFORE_PLAIN=$(mktemp dumpXXXX)
AFTER_PLAIN=$(mktemp dumpXXXX)
(zcat $BEFORE 2>/dev/null || cat $BEFORE) > $BEFORE_PLAIN
(zcat $AFTER 2>/dev/null || cat $AFTER) > $AFTER_PLAIN

java -cp sts_util.jar:. Differ $BEFORE_PLAIN $AFTER_PLAIN

rm $BEFORE_PLAIN
rm $AFTER_PLAIN
