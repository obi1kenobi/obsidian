redis                 = require('redis')
async                 = require('async')
fs                    = require('fs')
path                  = require('path')
logDebug              = require('../../logging').logDebug('connections::redis')
logError              = require('../../logging').logError('connections::redis')
{ config, constants } = require('../../common')
util                  = require('../../util')

BATCH_SIZE = 10000

preloadScriptFromFile = (file, cb) ->
  async.waterfall [
    (done) ->
      fs.readFile file, { encoding: 'utf8' }, done
    (script, done) ->
      Redis.client.script 'load', script, done
    (sha, done) ->
      file_name = path.basename(file)
      script_name = constants.REDIS_SCRIPT_FILES[file_name]
      logDebug "Loaded script #{script_name} from #{file_name}"
      Redis.scriptShas[script_name] = sha
      done()
  ], cb

preloadScripts = (cb) ->
  predicate = (file_path) ->
    return path.extname(file_path) == '.lua'

  async.waterfall [
    (done) ->
      util.recursivelyCollectFiles __dirname + '/../../../../redis_scripts', predicate, done
    (files, done) ->
      async.each files, preloadScriptFromFile, done
  ], cb

scanRedisKeys = (cursor, iterator, cb) ->
  new_cursor = null
  async.waterfall [
    (done) ->
      Redis.client.scan cursor, 'count', BATCH_SIZE, done
    (response, done) ->
      new_cursor = response[0]
      keys = response[1]
      async.each keys, iterator, done
  ], (err, res) ->
    if err?
      cb(err)
    else
      if new_cursor == '0'
        # done iterating
        cb(err, res)
      else
        process.nextTick () ->
          scanRedisKeys new_cursor, iterator, cb

Redis =
  client: null

  ###
  Iterates over all keys in the selected Redis database (default 0).

  Calls iterator with each key in turn, calls the callback when done.
  ###
  each: (iterator, cb) ->
    scanRedisKeys 0, iterator, cb

  ###
  Contains the SHA1 signatures of all scripts in the redis_scripts folder.

  Populated on initialization.
  ###
  scriptShas: {}

  initialize: (cb) ->
    if !client?
      { port, host, options } = config.redis
      Redis.client = redis.createClient(port, host, options)
      Redis.client.once 'ready', () ->
        preloadScripts cb
      Redis.client.on 'error', (err) ->
        logError 'Redis connection error:', err
    else
      process.nextTick cb


module.exports = Redis
