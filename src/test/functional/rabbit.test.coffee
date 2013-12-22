should                  = require('chai').should()
rabbit                  = require('../../lib/connections/rabbit')
{ config, constants }   = require('../../lib/common')

logDebug                = require('../../lib/logging').logDebug('rabbit::test')

{ QUEUES, EXCHANGES }   = constants

describe 'RabbitMQ connections', () ->
  before (done) ->
    rabbit.initialize done

  it 'should publish and receive messages', (done) ->
    test_object = { correct: true }
    checked = false

    rabbit.subscribe QUEUES.TEST_QUEUE, (message, headers, deliveryInfo, msgObj) ->
      should.exist message
      should.exist message.correct
      message.correct.should.equal test_object.correct

      msgObj.acknowledge()
      if checked
        done()
      else
        checked = true

    rabbit.publish EXCHANGES.TEST_EXCHANGE, '*', test_object, (err, res) ->
      should.not.exist err
      if checked
        done()
      else
        checked = true
