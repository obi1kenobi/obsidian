optimist           = require('optimist')
async              = require('async')
natural            = require('natural')
rabbit             = require('../connections/rabbit')
redis              = require('../connections/redis')
{ constants }      = require('../common')
logDebug           = require('../logging').logDebug('worker::wordCounter')
logError           = require('../logging').logError('worker::wordCounter')

tokenizer = new natural.RegexpTokenizer({ pattern: /[^a-zA-Z\-\']/ })

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

scriptedSaveHandler = (sha, signature, source, text, time, cb) ->
  redis.client.evalsha sha, 0, signature, source, text, (err, res) ->
    if err?
      logError 'Error updating tokens:', err
      nextTime = Math.min(time * 2, 30000)
      setTimeout scriptedSaveHandler, time, sha, signature, source, text, nextTime, cb
    else
      cb(null, res)

saveTokens = (hash, source, tokens, cb) ->
  async.series [
    (done) ->
      hash = '__hash__' + hash
      redis.client.set hash, source, done
    (done) ->
      async.each tokens, (item, callback) ->
        updateTokenHandler item, 500, callback
      , done
  ], cb

saveTokensScripted = (hash, source, tokens, cb) ->
  script_name = constants.REDIS_SCRIPTS.BATCH_INCREMENT
  text = tokens.join '|'
  sha = redis.scriptShas[script_name]
  hash = '__hash__' + hash
  scriptedSaveHandler sha, hash, source, text, 500, cb

processMessage = (message, headers, deliveryInfo, messageId) ->
  { text, hash, source } = message
  tokens = tokenizer.tokenize text

  # logDebug 'text:', text
  # logDebug 'tokens:', tokens

  saveTokensScripted hash, source, tokens, (err, res) ->
    if err?
      logError 'Error:', err
      rabbit.reject(messageId, true)
    else
      rabbit.acknowledge(messageId)

WordCounter =
  run: () ->
    USAGE = 'Count the number of occurrences of each word in all text queued up on Rabbit.'
    argv = optimist.usage(USAGE)
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
