redis                 = require('redis')
async                 = require('async')
fs                    = require('fs')
path                  = require('path')
logDebug              = require('../../logging').logDebug('connections::redis')
logError              = require('../../logging').logError('connections::redis')
{ config, constants } = require('../../common')
util                  = require('../../util')

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

Redis =
  client: null

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
