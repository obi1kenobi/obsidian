optimist           = require('optimist')
async              = require('async')
natural            = require('natural')
rabbit             = require('../connections/rabbit')
redis              = require('../connections/redis')
{ constants }      = require('../common')
logDebug           = require('../logging').logDebug('worker::wordCounter')
logError           = require('../logging').logError('worker::wordCounter')

tokenizer = new natural.RegexpTokenizer({ pattern: /[^\w\-\']/ })

updateTokenHandler = (item, time, cb) ->
  async.series [
    (done) ->
      redis.client.setnx item, 0, done
    (done) ->
      redis.client.incr item, done
  ], (err, res) ->
    if err?
      logError 'Error updating token:', err
      nextTime = Math.min(time * 2, 30000)
      setTimeout updateTokenHandler, time, item, nextTime, cb
    else
      cb(null, res)

processMessage = (message, headers, deliveryInfo, messageId) ->
  { text } = message
  tokens = tokenizer.tokenize text

  # logDebug 'text:', text
  # logDebug 'tokens:', tokens

  async.each tokens, (item, done) ->
    updateTokenHandler item, 500, done
  , (err, res) ->
    if err?
      logError 'Error:', err
      rabbit.reject(messageId, true)
    else
      rabbit.acknowledge(messageId)


WordCounter =
  run: () ->
    argv = optimist.usage('Count the number of occurrences of each word in all text queued up on Rabbit.')
                   .argv

    logDebug 'Worker starting...'

    async.parallel [
      (done) ->
        rabbit.initialize (err, res) ->
          if err?
            logError 'Couldn\'t initialize rabbit:', err
          done(err, res)
      (done) ->
        redis.initialize (err, res) ->
          if err?
            logError 'Couldn\'t initialize redis:', err
          done(err, res)
    ], (err, res) ->
      if err?
        logError 'Worker exiting with errors:', err
        process.exit(1)
      else
        rabbit.subscribe constants.QUEUES.LINE_QUEUE, processMessage


module.exports = WordCounter
