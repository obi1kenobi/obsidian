should                  = require('chai').should()
async                   = require('async')
redis                   = require('../../lib/connections/redis')
{ constants }           = require('../../lib/common')
logDebug                = require('../../lib/logging').logDebug('redis::test')

describe 'Redis connection', () ->
  before (cb) ->
    async.series [
      (done) ->
        redis.initialize done
      (done) ->
        redis.client.select 13, done
      (done) ->
        redis.client.flushdb done
    ], cb

  after (cb) ->
    async.series [
      (done) ->
        redis.client.flushdb done
    ], cb

  it 'should connect and process commands', (done) ->
    key = "test-key-1"
    value = "test-value-1"

    redis.client.set key, value, (err, res) ->
      should.not.exist err
      redis.client.get key, (err, res) ->
        should.not.exist err
        should.exist res
        res.should.equal value
        done()

  it 'should preload and execute scripts', (done) ->
    key = "test-key-2"
    value = "test-value-2"

    # this script should have been loaded on initialize
    sha = redis.scriptShas[constants.REDIS_SCRIPTS.SET_ALIAS_TEST]
    redis.client.evalsha sha, 1, key, value, (err, res) ->
      should.not.exist err
      redis.client.get key, (err, res) ->
        should.not.exist err
        should.exist res
        res.should.equal value
        done()

  it 'should iterate over all keys in current database', (done) ->
    keys = []
    values = []
    for item in [0...10]
      keys.push 'test-key-' + item.toString()
      values.push 'test-value-' + item.toString()

    async.each [0...10], (i, done) ->
      redis.client.set keys[i], values[i], done
    , (err, res) ->
      should.not.exist err
      async.each [0...10], (i, done) ->
        redis.client.get keys[i], (err, res) ->
          should.not.exist err
          should.exist res
          res.should.equal values[i]
          done(err, res)
      , (err, res) ->
        should.not.exist err
        done()
