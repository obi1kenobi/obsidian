optimist           = require('optimist')
async              = require('async')
fs                 = require('fs')
redis              = require('../../connections/redis')
{ constants }      = require('../../common')
logDebug           = require('../../logging').logDebug('worker::markovWords')
logError           = require('../../logging').logError('worker::markovWords')

letters = [ '^', '$',  # start and end of word tags
            '-', "'", 'a', 'b', 'c', 'd', 'e',
            'f', 'g', 'h', 'i', 'j', 'k', 'l',
            'm', 'n', 'o', 'p', 'q', 'r', 's',
            't', 'u', 'v', 'w', 'x', 'y', 'z' ]

n = 0
counts = null
keys_seen = 0
BATCH_SIZE = 10000

buildState = (depth) ->
  res = {}
  if depth > 1
    for l in letters
      res[l] = buildState depth-1
  else
    for l in letters
      res[l] = 0
  return res

updateState = (key, count) ->
  for c in key
    if c.toLowerCase() not in letters
      logDebug "Found malformed word, ignoring: #{key}"
      return

  word_base = ''
  for i in [1...n]
    word_base += '^'

  word = word_base + key.toLowerCase() + '$'

  # logDebug "Updating #{word} ngrams by #{count}"

  end = word.length - n
  for i in [0..end]
    ngram = word.substr(i, n)

    # logDebug "Updating ngram #{ngram}"

    start = counts
    for j in [0...n-1]
      start = start[ngram.charAt(j)]
    start[ngram.charAt(n-1)] += parseInt(count)

processWord = (key, cb) ->
  keys_seen++

  redis.client.get key, (err, count) ->
    if err?
      logError 'Error:', err
      cb(err)
    else
      updateState key, count
      cb()

scanRedisKeys = (cursor, cb) ->
  new_cursor = null
  logDebug 'Getting new batch of words, keys seen:', keys_seen
  async.waterfall [
    (done) ->
      redis.client.scan cursor, 'count', BATCH_SIZE, done
    (response, done) ->
      new_cursor = response[0]
      keys = response[1]
      async.each keys, processWord, done
  ], (err, res) ->
    if err?
      logError 'Error:', err

    if new_cursor == '0'
      cb(err, res)
    else
      process.nextTick () ->
        scanRedisKeys new_cursor, cb


constructModel = (cb) ->
  counts = buildState n
  scanRedisKeys 0, cb

outputModel = (file, cb) ->
  fs.writeFile file, JSON.stringify(counts), cb

MarkovWords =
  run: () ->
    check_fn = (argv) ->
      if argv.ngram < 2
        throw new Error("Can't analyze ngrams shorter than 2")
      return true
    USAGE = 'Construct a n-gram Markov model of word structure given word data in Redis.'
    argv = optimist.usage(USAGE)
                   .demand(['output'])
                   .default('ngram', 4)
                   .describe('output', 'Output file name')
                   .describe('ngram', 'Length of ngrams to analyze')
                   .check(check_fn)
                   .argv

    logDebug 'Worker starting...'

    n = argv.ngram

    async.series [
      (done) ->
        redis.initialize done
      (done) ->
        constructModel done
      (done) ->
        outputModel argv.output, done
    ], (err, res) ->
      if err?
        logError 'Worker exiting with errors:', err
        process.exit(1)
      else
        logDebug 'Done!'
        logDebug 'Keys seen:', keys_seen
        process.exit(0)

module.exports = MarkovWords