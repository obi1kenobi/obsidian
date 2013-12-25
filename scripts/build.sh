#!/bin/bash

# sanity check:
# this script deletes files left and right
# make sure that it's deleting the right ones
if [ "$0" != "./scripts/build.sh" ]; then
  echo "Build failed: Wrong cwd"
  echo "Executed from wrong cwd, you need to be in the obsidian root to call this script"
  exit 1
fi

echo "Removing existing build..."
rm -rf ./bin && mkdir ./bin

if [ "$?" -ne "0" ]; then
  exit 1
fi

# compile with source maps
echo "Compiling Coffeescript to JS..."
coffee --map --output ./bin/ --compile ./src/

if [ "$?" -ne "0" ]; then
  exit 1
fi

echo "Build successful!"