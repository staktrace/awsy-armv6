#!/usr/bin/env bash

SDK_TOOLS=$HOME/android/sdk/platform-tools

pushd fennec-addon-awsy >/dev/null
zip awsy.xpi bootstrap.js install.rdf
popd >/dev/null

pushd forwarder >/dev/null
javac -source 1.6 -target 1.6 *.java
$SDK_TOOLS/dx --dex --output=device-forwarder.jar *.class
jar cf host-forwarder.jar *.class
rm *.class
popd >/dev/null
