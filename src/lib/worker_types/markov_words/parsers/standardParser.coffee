USAGE = "
Pulls down chunks from Rabbit, parses them to break up text into sequences,
 and queues those sequences up back on Rabbit.\n
"

PARAMS = ""

async                       = require('async')
fs                          = require('fs')
path                        = require('path')
optimist                    = require('optimist')
{ constants }               = require('../../../common')
rabbit                      = require('../../../connections/rabbit')
logDebug                    = require('../../../logging').logDebug('parser:standard')
logError                    = require('../../../logging').logError('parser:standard')
util                        = require('../../../util')
parse                       = require('../../../parser')

HASH_ALGORITHM = 'sha1'

###
Takes a { chunk } message, hashes the chunk and parses it into sequences.
Queues up a { hash, seqs } object where hash is the base64 of the hash of the chunk,
and seqs is an array of sequences, each represented as a space-separated list of words.
###
processMessage = (message, headers, deliveryInfo, messageId) ->
  { chunk } = message
  hash = util.hashText(HASH_ALGORITHM, chunk)
  seqs = parse(chunk)
  rabbit.publish constants.EXCHANGES.SEQUENCE_EXCHANCE, '*', {hash, seqs}, (err, res) ->
    if err?
      logError 'Error when queueing up on Rabbit:', err
      rabbit.reject(messageId, true)
    else
      rabbit.acknowledge(messageId)


StandardParser =
  run: () ->
    argv = optimist.usage(USAGE + PARAMS)
                   .argv

    logDebug 'Worker starting...'

    rabbit.initialize (err, res) ->
      if err?
        logDebug 'Worker exiting with errors!'
        logError 'Error:', err
        process.exit(1)
      else
        rabbit.subscribe constants.QUEUES.CHUNK_QUEUE, processMessage

module.exports = StandardParser
