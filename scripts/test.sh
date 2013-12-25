#!/bin/bash

# sanity check
if [ "$0" != "./scripts/test.sh" ]; then
  echo "Start failed: Wrong cwd"
  echo "Executed from wrong cwd, you need to be in the obsidian root to call this script"
  exit 1
fi

# run build script
chmod +x ./scripts/build.sh && ./scripts/build.sh

# if build not successful, quit
if [ "$?" -ne "0" ]; then
  exit 1
fi

pushd ./bin

mocha --bail --recursive --reporter spec --ui bdd --timeout 2000 --slow 100

# if mocha failed, quit with exit code 1
if [ "$?" -ne "0" ]; then
  exit 1
fi

popd
