USAGE = "
Pulls down sequences from Rabbit and saves them in a hyperfile in append-only fashion\n
"

PARAMS = "Params:\n
--path [dir]\tThe directory where the hyperfile should be stored. It must be empty.
"

async                       = require('async')
fs                          = require('fs')
path                        = require('path')
optimist                    = require('optimist')
{ constants }               = require('../../../common')
rabbit                      = require('../../../connections/rabbit')
logDebug                    = require('../../../logging').logDebug('writer:sequence')
logError                    = require('../../../logging').logError('writer:sequence')
util                        = require('../../../util')
{ hyperfile }               = require('../../../appendonly')

###
Returns a function that handles { hash, seqs } messages and writes them to
the append-only hyperfile using the specified writer.
###
createMessageHandler = (writer) ->
  return (message, headers, deliveryInfo, messageId) ->
    writer.write message, (err, res) ->
      if err?
        logError 'Error on message:', message, err
        process.exit(1)
      else
        rabbit.acknowledge(messageId)

SequenceWriter =
  run: () ->
    argv = optimist.usage(USAGE + PARAMS)
                   .demand(['path'])
                   .argv

    logDebug 'Worker saving to path ', argv.path

    async.waterfall [
      (done) ->
        rabbit.initialize done
      (done) ->
        hyperfile.createWriter argv.path, done
    ], (err, writer) ->
      if err?
        logDebug 'Done with errors!'
        logError 'Error:', err
        process.exit(1)
      else
        messageHandler = createMessageHandler(writer)
        rabbit.subscribe constants.QUEUES.SEQUENCE_QUEUE, messageHandler


module.exports = SequenceWriter