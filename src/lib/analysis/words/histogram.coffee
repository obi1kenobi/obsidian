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
      # fast path, no overflows possible
      for l in word
        if !letter_map[l]?
          throw new Error('Word has unsupported letters. Word: ' + word)
        hist += 1 << letter_map[l]
      return hist
    else
      # slow path, guard against overflows
      counts = [0, 0, 0, 0, 0, 0, 0, 0]
      for l in word
        if !letter_map[l]?
          throw new Error('Word has unsupported letters. Word: ' + word)
        else if counts[letter_map[l] >> 2] < 15
          counts[letter_map[l] >> 2]++
          hist += 1 << letter_map[l]
      return hist

  difference: (hista, histb) ->
    diff = 0
    for i in [0...8]
      diff += Math.abs((hista & 15) - (histb & 15))
      hista >>= 4
      histb >>= 4
    return diff

init()

module.exports = Histogram
