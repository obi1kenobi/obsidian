USAGE = "
Recurisvely reads wikipedia files from a given directory, chunks them,
and sends each chunk to rabbit to be processed by a parser.\n
"

PARAMS = "Params:\n
--path [dir]\tThe path to recursively read files from.
"

async                       = require('async')
fs                          = require('fs')
path                        = require('path')
optimist                    = require('optimist')
{ constants }               = require('../../../common')
rabbit                      = require('../../../connections/rabbit')
logDebug                    = require('../../../logging').logDebug('chunker:wiki')
logError                    = require('../../../logging').logError('chunker:wiki')
util                        = require('../../../util')

MIN_CHUNK_SIZE = 4096

EXTENSIONS = ['.txt']

MAX_PARALLEL_FILES = 3

PUBLISH_DELAY = 1000

###
Send a RabbitMQ message to the chunk exchange for each chunk. Message format:

{
  "chunk": <chunk here>
}
###
processChunk = (chunk, chunkEnqueued) ->
  message = { chunk }
  rabbit.publish constants.EXCHANGES.CHUNK_EXCHANGE, '*', message, (err, res) ->
    if err?
      hash = util.hashText('md5', chunk)
      logError 'Error when publishing chunk with md5', hash, err
      setTimeout () ->
        processChunk(chunk, chunkEnqueued)
      , PUBLISH_DELAY
    else
      chunkEnqueued()

processText = (text, chunkCreated, chunkEnqueued) ->
  if text.length < MIN_CHUNK_SIZE
    return text
  else
    newline = text.indexOf('\n')
    while newline != -1 and newline < MIN_CHUNK_SIZE
      newline = text.indexOf('\n', newline + 1)

    if newline == -1
      return text
    else
      chunk = text.substr(0, newline+1)
      text = text.substr(newline+1)
      chunkCreated()
      processChunk(chunk, chunkEnqueued)
      return processText(text, chunkCreated, chunkEnqueued)

processFile = (file, cb) ->
  isDone = false
  hasError = false
  chunksInFlight = 0

  chunkEnqueued = () ->
    chunksInFlight--
    if isDone and chunksInFlight == 0 and !hasError
      logDebug 'Finished processing file', file
      cb()

  chunkCreated = () ->
    chunksInFlight++

  stream = fs.createReadStream file
  text = ''
  stream.on 'data', (chunk) ->
    text += chunk
    text = processText(text, chunkCreated, chunkEnqueued)
  stream.on 'end', () ->
    text += '\n'
    text = processText(text, chunkCreated, chunkEnqueued)
    if text.length > 0
      chunkCreated()
      processChunk(text, chunkEnqueued)
    isDone = true
  stream.on 'error', (err) ->
    # prevent the callback from being called twice
    hasError = true
    cb(err)

processFiles = (files, cb) ->
  async.eachLimit files, MAX_PARALLEL_FILES, processFile, cb

WikiChunker =
  run: () ->
    argv = optimist.usage(USAGE + PARAMS)
                   .demand(['path'])
                   .argv

    logDebug 'Worker starting from path', argv.path

    supportedExtension = (pathname) ->
      return path.extname(pathname) in EXTENSIONS

    async.waterfall [
      (done) ->
        rabbit.initialize done
      (done) ->
        util.recursivelyCollectFiles argv.path, supportedExtension, (err, files) ->
          if err?
            done(err)
          else
            processFiles files, done
      # async.waterfall is broken, can't put a waterfall inside another waterfall
      #(files, done) ->
      #  processFiles files, done
    ], (err, res) ->
      if err?
        logDebug 'Done with errors!'
        logError 'Error:', err
        process.exit(1)
      else
        logDebug 'Done!'
        process.exit(0)

module.exports = WikiChunker
