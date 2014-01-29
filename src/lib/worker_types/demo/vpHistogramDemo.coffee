_                     = require('underscore')
optimist              = require('optimist')
async                 = require('async')
fs                    = require('fs')
readline              = require('readline')
{ histogram, VPTree } = require('../analysis/words')
{ constants }         = require('../common')
logDebug              = require('../logging').logDebug('worker::vpHistogram')
logError              = require('../logging').logError('worker::vpHistogram')

argv = null
data = []
vpt = null
rl = null

initializeData = (words) ->
  metric = (a, b) ->
    return histogram.difference a.hist, b.hist
  logDebug 'Creating histograms...'
  for k, v of words
    data.push {hist: histogram.create(k.toLowerCase()), word: k}
  logDebug 'Creating VP tree...'
  vpt = new VPTree(data, metric)

validateInput = (line) ->
  valid = line?.length > 0 and line.split(' ').length == 1
  if valid
    for c in line
      if c not in constants.LETTERS
        return false
  return valid

getClosestWithVpt = (word, hist) ->
  item = {hist, word}
  start = Date.now()
  result = vpt.closestOne item
  end = Date.now()
  diff = histogram.difference result.hist, hist
  console.log "VPT: Closest word at distance #{diff}: #{result.word} (#{end-start}ms)\n"

getClosestWithLinearScan = (word, hist) ->
  bestdiff = Number.POSITIVE_INFINITY
  bestword = null
  count = 0
  start = Date.now()
  for d in data
    diff = histogram.difference d.hist, hist
    if diff < bestdiff
      count = 1
      bestdiff = diff
      bestword = d.word
    else if diff == bestdiff
      count++
  end = Date.now()
  console.log "Linear: Closest word (1 of #{count}) at distance #{bestdiff}:
 #{bestword} (#{end-start}ms)\n"

processLine = (line) ->
  line = line.toLowerCase().trim()
  if !validateInput(line)
    console.log "Not a valid word: #{line}\n"
    rl.prompt()
    return
  hist = histogram.create line
  getClosestWithVpt line, hist
  getClosestWithLinearScan line, hist
  rl.prompt()

VPHistogramDemo =
  run: () ->
    USAGE = 'Demo the VP tree + histogram functionality for spell checking.\nParams: --input [file]'
    argv = optimist.usage(USAGE)
                   .demand(['input'])
                   .argv

    logDebug 'Reading file...'
    rl = readline.createInterface(process.stdin, process.stdout)
    rl.setPrompt('Demo > ')
    words = JSON.parse fs.readFileSync argv.input, { encoding: 'utf8' }

    logDebug "File loaded: #{_.size words} words found."
    initializeData(words)

    logDebug 'Done!'
    console.log 'Type in a word (not necessarily correct) to try to spell-check it.'

    rl.prompt()
    rl.on 'line', processLine
    rl.on 'close', () ->
      process.exit(0)

module.exports = VPHistogramDemo
