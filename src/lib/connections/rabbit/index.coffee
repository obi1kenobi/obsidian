amqp               = require('amqp')
async              = require('async')
logDebug           = require('../../logging').logDebug('connections::rabbit')
{ config }         = require('../../common')

queues = {}
exchanges = {}
publishOptions = {}
subscribeOptions = {}
connection = null

Rabbit =
  _createExchanges: (cb) ->
    async.each config.rabbit.exchanges, (spec, done) ->
      publishOptions[spec.name] = spec.publishOptions
      exchanges[spec.name] = connection.exchange spec.name, spec.options, () ->
        done()
    , cb

  _createQueues: (cb) ->
    async.each config.rabbit.queues, (spec, done) ->
      subscribeOptions[spec.name] = spec.subscribeOptions
      queues[spec.name] = connection.queue spec.name, spec.options, () ->
        if spec.bindings?.length > 0
          for b in spec.bindings
            queues[spec.name].bind b.exchange, b.routingKey
        done()
    , cb

  ###
  Sets up the exchanges and queues as specified.
  ###
  initialize: (cb) ->
    args = config.rabbit.connection
    connection = amqp.createConnection args.options, args.implOptions
    connection.once 'ready', () ->
      async.series [
        (callback) ->
          Rabbit._createExchanges callback
        (callback) ->
          Rabbit._createQueues callback
      ], cb
    connection.on 'error', (err) ->

  ###
  Publish the message to the given exchange name with the specified key.

  @param cb (error, result)
  ###
  publish: (exchange, routingKey, message, cb) ->
    exchanges[exchange].publish routingKey, message, publishOptions[exchange], (hasError, err) ->
      cb(err, null)

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
