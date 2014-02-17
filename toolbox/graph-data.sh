#!/usr/bin/env bash

javac -cp sts_util.jar Parser.java Plotter.java
pushd ..
rm -rf plotter-results
mkdir plotter-results
ls -1 data/mozilla-inbound/*/*-TabsClosedForceGC-* | sort | head -n 175 | xargs java -cp toolbox/sts_util.jar:toolbox/ Plotter
mv table.html table.plot table.data plotter-results
pushd plotter-results
gnuplot table.plot
for i in graph-*.png; do
    convert $i -resize 80x60 ${i//graph/thumb}
done
popd
popd
