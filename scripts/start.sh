#!/usr/bin/env bash

# stop immediately if any process returns non-zero exit code
set -e

# sanity check
if [ "$0" != "./scripts/start.sh" ]; then
  echo "Start failed: Wrong cwd"
  echo "Executed from wrong cwd, you need to be in the obsidian root to call this script"
  exit 1
fi

# run build script
chmod +x ./scripts/build.sh && ./scripts/build.sh

echo "Starting..."
echo ""
node ./bin/index.js
