fs                     = require('fs')
path                   = require('path')
async                  = require('async')
util                   = require('../util')
serializer             = require('./serializer')

EXTENSION              = '.hyper'
ENCODING               = 'utf8'
DEFAULT_FILE_SIZE_HINT = 64 * 1024 * 1024  # approximate size of each file in the Hyperfile

validateFiles = (fileNumbers) ->
  for i in [0...fileNumbers.length]
    if i != fileNumbers[i]
      throw new Error("File #{i} is missing in hyperfile!")

numericSort = (array) ->
  array.sort (a, b) -> a-b

reorderFiles = (files, cb) ->
  async.map files, (item, callback) ->
    filename = path.basename(item, EXTENSION)
    fileNum = null
    try
      fileNum = parseInt(filename)
    catch e
      callback(e)
      callback = () ->
      return
    callback(null, fileNum)
  , (err, fileNumbers) ->
    if err?
      cb(err)
      cb = () ->
      return
    else
      # coffeescript doesn't have object comprehensions :'(
      fileMap = {}
      for i in [0...files.length]
        fileMap[fileNumbers[i]] = files[i]
      numericSort(fileNumbers)
      try
        validateFiles(fileNumbers)
      catch e
        cb(e)
        cb = () ->
        return
      fileOrder = (fileMap[i] for i in [0...files.length])
      cb(null, fileOrder)

readFile = (file, iterator, cb) ->
  stream = fs.createReadStream(file)
  text = ''
  stream.on 'data', (chunk) ->
    text += chunk
    result = serializer.parse(text)
    text = result.remainder
    async.each result.entries, iterator, (err, res) ->
      if text != '' and !err?
        err = new Error("Unreadable entry at the end of file #{file}: #{text}")
      if err?
        stream.removeAllListeners()
        # the stream is closed automatically on end and error, but this case is neither
        stream.close()
        cb(err)
        cb = () ->
        iterator = () ->
  stream.once 'end', () ->
    stream.removeAllListeners()
    cb()
  stream.once 'error', (err) ->
    stream.removeAllListeners()
    cb(err)

supportedExtension = (pathname) ->
  return path.extname(pathname) == EXTENSION

###
Writer class for hyperfiles. Intentionally doesn't handle stream errors, because they
could leave the hyperfile in an inconsistent state from which it is impossible to recover
programmatically.
###
class HyperfileWriter
  constructor: (@_path, @_lastFileNumber, @_fileSizeHint) ->
    if !@_fileSizeHint?
      @_fileSizeHint = DEFAULT_FILE_SIZE_HINT
    @_currentStream = null
    @_currentFileSize = 0
    @_init()

  ###
  Write the specified object as an append-only entry.

  @async
  @param entry {Object} The object to serialize and write as an entry.
  @param cb    {function} (optional) callback, called when the data is flushed.
  ###
  write: (entry, cb) ->
    data = serializer.serialize(entry)
    @_currentFileSize += data.length
    if @_needNewFile()
      @_currentStream.end(data, ENCODING, cb)
      @_createNewFile()
    else
      @_currentStream.write(data, ENCODING, cb)

  ###
  Closes the writer.

  @async
  @param cb {function} (optional) called when all outstanding writes have completed.
  ###
  close: (cb) ->
    @_currentStream.end(cb)

  _init: () ->
    if @_lastFileNumber == -1
      @_createNewFile()
    else
      @_inspectFile()
      if @_needNewFile()
        @_createNewFile()
      else
        @_openExistingFile()

  _createFileName: () ->
    return path.resolve(@_path, '' + @_lastFileNumber + EXTENSION)

  _inspectFile: () ->
    fileName = @_createFileName()
    @_currentFileSize = fs.statSync(fileName).size

  _needNewFile: () ->
    return @_currentFileSize >= @_fileSizeHint

  _openExistingFile: () ->
    fileName = @_createFileName()
    args =
      flags: 'a'  # open for appending
      encoding: ENCODING
    @_currentStream = fs.createWriteStream(fileName, args)

  _createNewFile: () ->
    @_lastFileNumber++
    fileName = @_createFileName()
    args =
      flags: 'ax'  # open exclusively, file must not already exist (to prevent data loss)
      encoding: ENCODING
    @_currentStream = fs.createWriteStream(fileName, args)
    @_currentFileSize = 0


###
A Hyperfile is a sequence of files of preset max size, which are generated by
appending data to the end of the last file in the sequence.

Allowed operations:
- appending an encoded entry to the end of the Hyperfile
- reading entries from the Hyperfile, in no particular order (for performance reasons)
###
Hyperfile =
  ###
  Reads a hyperfile at the specified path. The iterator is called with every entry in
  the hyperfile. For performance's sake, there is no guarantee on the order in which the
  data will be extracted or the order in which iterators will complete.

  @async
  @param path     {String} The path to the hyperfile
  @param iterator {function} The function to be executed on every entry; it's called with
                             iterator(entry, callback). The callback is a callback(error)
                             which will stop further reads if called with an error.
  @param cb       {function} callback
  ###
  readEntries: (path, iterator, cb) ->
    async.waterfall [
      (done) ->
        util.recursivelyCollectFiles path, supportedExtension, done
      (files, done) ->
        reorderFiles files, done
      (files, done) ->
        async.eachSeries files, (item, callback) ->
          readFile item, iterator, callback
        , done
    ], cb

  ###
  Creates a hyperfile writer at the specified path.

  @async
  @param path         {String} The path to the hyperfile.
  @param fileSizeHint {Number} (optional) A hint for the desired file size.
  @param cb           {function} callback(error, writer)
  ###
  createWriter: (path, fileSizeHint, cb) ->
    if !cb? and typeof fileSizeHint == 'function'
      cb = fileSizeHint
      fileSizeHint = undefined
    async.waterfall [
      (done) ->
        util.recursivelyCollectFiles path, supportedExtension, done
      (files, done) ->
        reorderFiles files, done
      (files, done) ->
        res = null
        try
          res = new HyperfileWriter(path, files.length - 1, fileSizeHint)
        catch e
          done(e)
          done = () ->
          return
        done null, res
    ], cb


module.exports = Hyperfile
