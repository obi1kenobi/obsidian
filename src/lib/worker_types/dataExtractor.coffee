optimist           = require('optimist')
async              = require('async')
fs                 = require('fs')
redis              = require('../connections/redis')
{ constants }      = require('../common')
logDebug           = require('../logging').logDebug('worker::dataExtractor')
logError           = require('../logging').logError('worker::dataExtractor')

argv = null
data = {}

processKey = (key, cb) ->
  if key.length > argv.maxlen
    process.nextTick cb
  else
    redis.client.get key, (err, res) ->
      if parseInt(res) >= argv.minfreq
        data[key] = res
      cb(err, res)

reportProgress = (count) ->
  logDebug "#{count} keys processed."

saveOutput = (output, cb) ->
  fs.writeFileSync output, JSON.stringify(data)
  cb()

DataExtractor =
  run: () ->
    argv = optimist.usage('Extract all keys and values from database 0 of Redis and save them as a JSON file.\nParams: --output [file]')
                   .demand(['output'])
                   .default('minfreq', 0)
                   .default('maxlen', 1 << 20)
                   .argv

    logDebug 'Worker starting...'

    async.series [
      (done) ->
        redis.initialize done
      (done) ->
        redis.each processKey, reportProgress, done
      (done) ->
        logDebug 'Saving output file...'
        saveOutput argv.output, done
    ], (err, res) ->
      if err?
        logError 'Exiting with error:', err
        process.exit(1)
      else
        logDebug 'Done!'
        process.exit(0)

module.exports = DataExtractor
