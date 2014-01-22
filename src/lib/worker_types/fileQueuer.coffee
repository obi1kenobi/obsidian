optimist                    = require('optimist')
fs                          = require('fs')
path                        = require('path')
async                       = require('async')
lazy                        = require('lazy.js')
crypto                      = require('crypto')
{ constants }               = require('../common')
rabbit                      = require('../connections/rabbit')
logDebug                    = require('../logging').logDebug('worker::fileQueuer')
logError                    = require('../logging').logError('worker::fileQueuer')
{ recursivelyCollectFiles } = require('../util')

extensions = ['.txt']

supportedExtension = (pathname) ->
  return path.extname(pathname) in extensions

createHash = (text) ->
  return crypto.createHash('sha1').update(text, 'utf8').digest('base64')

###
Sends a RabbitMQ message to the line exchange for every line. Message format:

{
  "text": <line here>,
  "source": <filename>,
  "hash": <base64 sha1 hash of the line>
}
###
processLine = (file, line, hash, attempt) ->
  message =
    text: line
    source: file
    hash: hash

  rabbit.publish constants.EXCHANGES.LINE_EXCHANGE, '*', message, (err, res) ->
    if err?
      logError 'Error when publishing hash', hash, err
      attempt++
      if attempt < 5
        process.nextTick processLine(file, line, hash, attempt)
      else
        logError 'Max retries reached; giving up on hash', hash

processFile = (file, cb) ->
  eachFn = (line) ->
    processLine(file, line, createHash(line), 0)

  stream = fs.createReadStream(file)
  stream.on 'end', () ->
    logDebug 'Finished processing file', file
    cb()

  stream.on 'error', (err) ->
    logDebug 'Error processing file:', err
    cb()

  lazy(stream)
      .lines()
      .each(eachFn)


FileQueuer =
  run: () ->
    USAGE = 'Recursively queue up the lines from all files in the given directory\n
Params: --path [dir]'
    argv = optimist.usage(USAGE)
                   .demand(['path'])
                   .argv

    logDebug 'Worker starting from path', argv.path

    rabbit.initialize (err, res) ->
      if err?
        logError 'Couldn\'t initialize rabbit:', err
      else
        recursivelyCollectFiles argv.path, supportedExtension, (err, files) ->
          if err?
            logError 'Error collecting files:', err
          else
            logDebug 'Found files:', files
            async.eachLimit files, 3, processFile, (err, res) ->
              if err?
                logDebug 'Done with errors!'
                logError 'Errors:', err
              else
                logDebug 'Done!'
              process.exit(0)


module.exports = FileQueuer
