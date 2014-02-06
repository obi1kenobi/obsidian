#!/usr/bin/env bash

# stop immediately if any process returns non-zero exit code
set -e

# sanity check:
# this script deletes files left and right
# make sure that it's deleting the right ones
if [ "$0" != "./scripts/runSequenceWriter.sh" ]; then
  echo "Build failed: Wrong cwd"
  echo "Executed from wrong cwd, you need to be in the obsidian root to call this script"
  exit 1
fi

# run build script
chmod +x ./scripts/build.sh && ./scripts/build.sh

# remove existing logs
if [ -d /var/log/obsidian/sequenceWriter ]; then
  echo "Removing existing logs..."
  rm -r /var/log/obsidian/sequenceWriter
fi

# delete any existing sequences
if [ -d ./data/sequences ]; then
  echo "Existing sequence data found!"
  echo "Removing data in 2 seconds, CTRL-C to stop..."
  sleep 2
  rm -r ./data/sequences
fi

mkdir -p /var/log/obsidian/sequenceWriter
mkdir -p ./data/sequences

node ./bin/index.js --type=sequenceWriter --path=./data/sequences >/var/log/obsidian/sequenceWriter/stdout.log 2>/var/log/obsidian/sequenceWriter/stderr.log &

sleep 1
tail -F -n 1000 /var/log/obsidian/sequenceWriter/*
