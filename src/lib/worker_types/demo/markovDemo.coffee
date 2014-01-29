optimist           = require('optimist')
async              = require('async')
readline           = require('readline')
fs                 = require('fs')
{ constants }      = require('../../common')
logDebug           = require('../../logging').logDebug('worker::markovDemo')
logError           = require('../../logging').logError('worker::markovDemo')

params = null
argv = null
rl = null  # console interface

letters = [ '-', "'", 'a', 'b', 'c', 'd', 'e',
            'f', 'g', 'h', 'i', 'j', 'k', 'l',
            'm', 'n', 'o', 'p', 'q', 'r', 's',
            't', 'u', 'v', 'w', 'x', 'y', 'z' ]

validateInput = (line) ->
  valid = line?.length > 0 and line.split(' ').length == 1
  if valid
    for c in line
      if c not in letters
        return false
  return valid

prepWord = (word, n) ->
  word_base = ''
  for i in [1...n]
    word_base += '^'
  return word_base + word.toLowerCase() + '$'

calculateCoefficient = (word) ->
  length = word.length
  n = argv.ngram
  word = prepWord(word, n)

  end = word.length - n
  coeff = 0
  for i in [0..end]
    ngram = word.substr(i, )

    p = params
    for j in [0...n]
      p = p[ngram.charAt(j)]
    coeff += p

  return { absolute: coeff, normalized: coeff / length }

processLine = (line) ->
  line = line.toLowerCase().trim()
  if !validateInput(line)
    console.log "Not a valid word: #{line}\n"
    rl.prompt()
    return
  results = calculateCoefficient(line)
  output = "Word probability coeff: #{results.absolute.toFixed(3)};
 Length-normalized: #{results.normalized.toFixed(3)}\n"
  console.log output
  rl.prompt()

MarkovDemo =
  run: () ->
    argv = optimist.usage('Demo Markov model for letters in a word based on given data')
                   .demand(['input'])
                   .default('ngram', 4)
                   .default('mode', 'word')
                   .describe('input', 'Input file name')
                   .describe('ngram', 'Length of ngrams to normalize')
                   .describe('mode', "Normalization mode: 'word' or 'phrase' (currently ignored)")
                   .argv

    rl = readline.createInterface(process.stdin, process.stdout)
    rl.setPrompt('Demo > ')
    params = JSON.parse fs.readFileSync argv.input, { encoding: 'utf8' }
    console.log 'Type in a word to run it through the Markov model.'
    console.log 'Keep in mind that likely words will have small coefficients with neglog data,
 and high coefficients with fractional data.\n'

    rl.prompt()
    rl.on 'line', processLine
    rl.on 'close', () ->
      process.exit(0)

module.exports = MarkovDemo