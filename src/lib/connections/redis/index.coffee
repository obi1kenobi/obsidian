redis        = require('redis')
async        = require('async')
logDebug     = require('../../logging').logDebug('connections::redis')
{ config }   = require('../../common')

Redis =
  client: null

  initialize: (cb) ->
    if !client?
      { port, host, options } = config.redis
      Redis.client = redis.createClient(port, host, options)
      Redis.client.once 'ready', cb
    else
      process.nextTick cb


module.exports = Redis
