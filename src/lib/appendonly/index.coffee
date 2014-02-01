SEPARATOR = '\n'

###
Methods to serialize and parse entries to append-only files.
###
AppendOnly =
  ###
  Takes an object and serializes it into the append-only format.

  @param entry {Object} the object to serialize
  @returns {String} the encoded form of the parameter
  ###
  serialize: (entry) ->
    return JSON.stringify(entry) + SEPARATOR

  ###
  Parses out all objects inside the given string, and returns any fragment of the
  string that couldn't be processed.

  @param data {String} the data to parse
  @returns {Object} an { entries, remainder } object
                    entries {Array} array of objects that contains all entries found
                    remainder {String} the part of the string that was not a full entry
                                       and couldn't be parsed yet;
                                       or empty string, if no remainder exists
  ###
  parse: (data) ->
    if data.indexOf(SEPARATOR) == -1
      return { entries: [], remainder: data }

    jsons = data.split(SEPARATOR)
    entries = (JSON.parse(jsons[i]) for i in [0...jsons.length - 1])

    lastEntry = null
    remainder = jsons[jsons.length - 1]

    if remainder != ''
      try
        lastEntry = JSON.parse(data[jsons.length - 1])
      catch e
        # ignore error, incomplete entry

    if lastEntry?
      remainder = ''
      entries.push lastEntry

    return { entries, remainder }


module.exports = AppendOnly
