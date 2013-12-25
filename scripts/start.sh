#!/bin/bash

# sanity check
if [ "$0" != "./scripts/start.sh" ]; then
  echo "Start failed: Wrong cwd"
  echo "Executed from wrong cwd, you need to be in the obsidian root to call this script"
  exit 1
fi

# run build script
chmod +x ./scripts/build && ./scripts/build

# if build not successful, quit
if [ "$?" -ne "0" ]; then
  exit 1
fi

echo "Starting..."
echo ""
node ./bin/index.js