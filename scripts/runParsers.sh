#!/usr/bin/env bash

# stop immediately if any process returns non-zero exit code
set -e

# sanity check:
# this script deletes files left and right
# make sure that it's deleting the right ones
if [ "$0" != "./scripts/runParsers.sh" ]; then
  echo "Build failed: Wrong cwd"
  echo "Executed from wrong cwd, you need to be in the obsidian root to call this script"
  exit 1
fi

# run build script
chmod +x ./scripts/build.sh && ./scripts/build.sh

# remove existing logs
if [ -d /var/log/obsidian/parser ]; then
  echo "Removing existing logs..."
  rm -r /var/log/obsidian/parser
fi

mkdir -p /var/log/obsidian/parser

node ./bin/index.js --type=standardParser >/var/log/obsidian/parser/1-stdout.log 2>/var/log/obsidian/parser/1-stderr.log &
node ./bin/index.js --type=standardParser >/var/log/obsidian/parser/2-stdout.log 2>/var/log/obsidian/parser/2-stderr.log &
node ./bin/index.js --type=standardParser >/var/log/obsidian/parser/3-stdout.log 2>/var/log/obsidian/parser/3-stderr.log &
# node ./bin/index.js --type=standardParser >/var/log/obsidian/parser/4-stdout.log 2>/var/log/obsidian/parser/4-stderr.log &

sleep 1
tail -F -n 1000 /var/log/obsidian/parser/*stderr*
