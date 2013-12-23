optimist        = require('optimist')
fs              = require('fs')
path            = require('path')
async           = require('async')
lazy            = require('lazy.js')
crypto          = require('crypto')
{ constants }   = require('../common')
rabbit          = require('../connections/rabbit')
logDebug        = require('../logging').logDebug('worker::fileQueuer')

extensions = ['.txt']

supportedExtension = (pathname) ->
  return path.extname(pathname) in extensions

recursivelyCollectFiles = (start_path, cb) ->
  async.waterfall [
    (done) ->
      fs.readdir(start_path, done)
    (files, done) ->
      async.map files, (item, callback) ->
        full_path = path.resolve(start_path, item)
        if fs.lstatSync(full_path).isDirectory()
          recursivelyCollectFiles full_path, callback
        else
          if supportedExtension(full_path)
            callback(null, [full_path])
          else
            callback(null, [])
      , (err, res) ->
        if err?
          done(err)
        else
          done(null, [].concat.apply([], res))
  ], cb

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
      logDebug 'Error when publishing hash', hash, err
      attempt++
      if attempt < 5
        process.nextTick processLine(file, line, hash, attempt)
      else
        logDebug 'Max retries reached; giving up on hash', hash

processFile = (file, cb) ->
  eachFn = (line) ->
    processLine(file, line, createHash(line), 0)

  stream = fs.createReadStream(file);
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
    argv = optimist.usage('Recursively queue up the lines from all files in the given directory\nParams: --path [dir]')
                   .demand(['path'])
                   .argv

    logDebug 'Worker starting from path', argv.path

    rabbit.initialize (err, res) ->
      if err?
        logDebug 'Couldn\'t initialize rabbit:', err
      else
        recursivelyCollectFiles argv.path, (err, files) ->
          if err?
            logDebug 'Error collecting files:', err
          else
            logDebug 'Found files:', files
            async.each files, processFile, (err, res) ->
              if err?
                logDebug 'Done with errors:', err
              else
                logDebug 'Done!'
              process.exit(0)


module.exports = FileQueuer
