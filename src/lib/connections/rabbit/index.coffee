amqp               = require('amqp')
async              = require('async')
logDebug           = require('../../logging').logDebug('connections::rabbit')
logError           = require('../../logging').logError('connections::rabbit')
{ config }         = require('../../common')

queues = {}
exchanges = {}
publishOptions = {}
subscribeOptions = {}
connection = null

createExchanges = (cb) ->
  async.each config.rabbit.exchanges, (spec, done) ->
    publishOptions[spec.name] = spec.publishOptions
    exchanges[spec.name] = connection.exchange spec.name, spec.options, () ->
      done()
  , cb

createQueues = (cb) ->
  async.each config.rabbit.queues, (spec, done) ->
    subscribeOptions[spec.name] = spec.subscribeOptions
    queues[spec.name] = connection.queue spec.name, spec.options, () ->
      if spec.bindings?.length > 0
        for b in spec.bindings
          queues[spec.name].bind b.exchange, b.routingKey
      done()
  , cb

Rabbit =

  ###
  Sets up the exchanges and queues as specified.
  ###
  initialize: (cb) ->
    if !connection?
      args = config.rabbit.connection
      connection = amqp.createConnection args.options, args.implOptions
      connection.once 'ready', () ->
        async.series [
          (callback) ->
            createExchanges callback
          (callback) ->
            createQueues callback
        ], (err, res) ->
          cb(err)
      connection.on 'error', (err) ->
        logError 'Rabbit connection error:', err
    else
      process.nextTick cb

  ###
  Publish the message to the given exchange name with the specified key.

  @param cb (error, result)
  ###
  publish: (exchange, routingKey, message, cb) ->
    exchanges[exchange].publish routingKey, message, publishOptions[exchange], (hasError, err) ->
      cb(err)

  ###
  Subscribe to the given queue name.

  @param listener (message, headers, deliveryInfo, innerMsgObj)
  ###
  subscribe: (queue, listener) ->
    queues[queue].subscribe subscribeOptions[queue], listener

  ###
  Because the amqp driver is badly designed, we have to mess with the innards to ack/nack messages.
  ###
  acknowledge: (innerMsgObj) ->
    innerMsgObj.acknowledge()

  reject: (innerMsgObj, requeue) ->
    innerMsgObj.reject(requeue)


module.exports = Rabbit
