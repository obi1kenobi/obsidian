_        = require('underscore')
logDebug = require('../logging').logDebug('parser:index')

SEPARATORS = '`!,.:;"?/\|[]{}()*&<>'

ILLEGAL = '@#$%^0123456789_=+'

splitOnSeparators = (chunk) ->
  regex = /[`\!,\.:;"\?\/\\\|\[\]\{\}\(\)\*&<>]/gi
  return chunk.split(regex)

discardIllegalChars = (chunk) ->
  regex = ///
          (^|\s)                  # match start of string or whitespace
          ([^@\#\$%\^0-9_=\+\s]*) # match zero or more non-whitespace, non-illegal
          ([@\#\$%\^0-9_=\+]+)    # match illegal char
          ([^@\#\$%\^0-9_=\+\s]*) # match zero or more non-whitespace, non-illegal
          ($|\s)                  # match end of string or whitespace
          ///gi
  replacement = '$1|$5'
  chunk = chunk.replace(regex, replacement)
  return chunk.split('|')

allowOnlyWordChars = (chunk) ->
  regex = ///
          (^|\s)               # match start of string or whitespace
          ([a-zA-Z'\-]*)       # match zero or more word characters
          ([^\sa-zA-Z'\-]+)    # match illegal char
          ([a-zA-Z'\-]*)       # match zero or more word characters
          ($|\s)               # match end of string or whitespace
          ///gi
  replacement = '$1|$5'
  m = chunk.match(regex)
  if m?
    logDebug "Discarding illegal words", m
    chunk = chunk.replace(regex, replacement)
    return chunk.split('|')
  else
    return chunk

removeSurplusWhitespace = (chunk) ->
  regex = /\s+/gi  # match one or more whitespace chars
  chunk = chunk.trim().replace(regex, ' ')
  return chunk

###
Parses raw text chunks into space-separated word sequences that are suitable
for forming n-grams.

See ideas.txt for detailed explanation of the internals.
###
parse = (chunk) ->
  split = splitOnSeparators(chunk)
  arr = []
  for s in split
    arr.push discardIllegalChars(s)

  split = _.flatten(arr)
  arr = []
  for s in split
    arr.push allowOnlyWordChars(s)

  split = _.flatten(arr)
  arr = []
  for s in split
    s = removeSurplusWhitespace(s)
    if s.length > 0
      arr.push s
  return arr


module.exports = parse
