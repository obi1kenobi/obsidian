{ constants } = require('../../common')

logDebug      = require('../../logging').logDebug('analysis::word::histogram')

letter_map = {}

init = () ->
  for i in [0...constants.LETTERS.length - 2]
    letter_map[constants.LETTERS[i]] = (i % 8) << 2
  letter_map = Object.freeze letter_map

Histogram =
  create: (word) ->
    hist = 0
    if word.length <= 15
      for l in word
        if !letter_map[l]?
          throw new Error('Word has unsupported letters. Word: ' + word)
        hist += 1 << letter_map[l]
      return hist
    else
      throw new Error('Word too long, length should be 15 or less. Word: ' + word)

  difference: (hista, histb) ->
    diff = 0
    for i in [0...8]
      diff += Math.abs(hista & 15, histb & 15)
      hista >>= 4
      histb >>= 4
    return diff

init()

module.exports = Histogram
