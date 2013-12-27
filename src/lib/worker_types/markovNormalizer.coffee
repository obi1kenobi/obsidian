optimist           = require('optimist')
async              = require('async')
fs                 = require('fs')
{ constants }      = require('../common')
logDebug           = require('../logging').logDebug('worker::markovNormalizer')
logError           = require('../logging').logError('worker::markovNormalizer')

fractionNormalize = (number, total) ->
  if total == 0
    return 0
  return number / total

neglogNormalize = (number, total) ->
  if number == 0
    return Number.POSITIVE_INFINITY
  return Math.log(total) - Math.log(number)

normalizeLevel = (counts, level, normalizationFn) ->
  result = {}
  if level <= 1
    total_count = 0
    for k, v of counts
      total_count += v
    for k, v of counts
      result[k] = normalizationFn v, total_count
  else
    for k, v of counts
      result[k] = normalizeLevel v, level - 1, normalizationFn
  return result

normalize = (args, cb) ->
  normalizationFn = null
  if args.mode == 'neglog'
    normalizationFn = neglogNormalize
  else if args.mode == 'fraction'
    normalizationFn = fractionNormalize
  else
    throw 'Unrecognized normalization mode ' + args.mode

  counts = JSON.parse fs.readFileSync args.input, { encoding: 'utf8' }
  result = normalizeLevel counts, args.ngram, normalizationFn

  fs.writeFileSync args.output, JSON.stringify(result)
  process.nextTick cb

MarkovNormalizer =
  run: () ->
    check_fn = (argv) ->
      if argv.ngram < 2
        throw "Can't analyze ngrams shorter than 2"
      return true

    argv = optimist.usage('Normalize Markov chain counts into neglog or fractional counts.')
                   .demand(['output', 'input'])
                   .default('ngram', 4)
                   .default('mode', 'neglog')
                   .describe('input', 'Input file name')
                   .describe('ngram', 'Length of ngrams to normalize')
                   .describe('output', 'Output file name')
                   .describe('mode', "Normalization mode: 'neglog' or 'fraction'")
                   .check(check_fn)
                   .argv

    logDebug 'Worker starting...'

    normalize argv, (err, res) ->
      if err?
        logError 'Worker exiting with errors:', err
        process.exit(1)
      else
        logDebug 'Done!'
        process.exit(0)

module.exports = MarkovNormalizer