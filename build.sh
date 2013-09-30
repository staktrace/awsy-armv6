#!/usr/bin/env bash

SDK_TOOLS=$HOME/android/sdk/platform-tools

pushd fennec-addon-awsy >/dev/null
zip awsy.xpi bootstrap.js install.rdf
popd >/dev/null

pushd forwarder >/dev/null
javac -source 1.6 -target 1.6 *.java
$SDK_TOOLS/../build-tools/android-4.3/dx --dex --output=device-forwarder.jar *.class
jar cf host-forwarder.jar *.class
rm *.class
popd >/dev/null

pushd awsy-data-generator >/dev/null
javac -cp sts_util.jar *.java
popd >/dev/null
