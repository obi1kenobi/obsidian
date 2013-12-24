redis        = require('redis')
async        = require('async')
logDebug     = require('../../logging').logDebug('connections::redis')
logError     = require('../../logging').logError('connections::redis')
{ config }   = require('../../common')

Redis =
  client: null

  initialize: (cb) ->
    if !client?
      { port, host, options } = config.redis
      Redis.client = redis.createClient(port, host, options)
      Redis.client.once 'ready', cb
      Redis.client.on 'error', (err) ->
        logError 'Redis connection error:', err
    else
      process.nextTick cb


module.exports = Redis
