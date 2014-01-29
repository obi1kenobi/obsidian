#!/usr/bin/env bash

# stop immediately if any process returns non-zero exit code
set -e

# sanity check:
# this script deletes files left and right
# make sure that it's deleting the right ones
if [ "$0" != "./scripts/chunkAllWiki.sh" ]; then
  echo "Build failed: Wrong cwd"
  echo "Executed from wrong cwd, you need to be in the obsidian root to call this script"
  exit 1
fi

# run build script
chmod +x ./scripts/build.sh && ./scripts/build.sh

# avoid memory leaks by exiting after 25 files of 20MB each :)
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AA/A
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AA/B
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AA/C
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AA/D
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AB/A
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AB/B
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AB/C
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AB/D
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AC/A
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AC/B
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AC/C
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AC/D
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AD/A
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AD/B
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AD/C
node ./bin/index.js --type=wikiChunker --path=../../Data/wiki_all/AD/D
