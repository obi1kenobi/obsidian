should                  = require('chai').should()
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
      (done) ->
        redis.client.script 'flush', done
    ], cb

  after (cb) ->
    async.series [
      (done) ->
        redis.client.flushdb done
      (done) ->
        redis.client.script 'flush', done
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
    for i in [0...10]
      keys.append 'test-key-' + item.toString()
      value.append 'test-value-' + item.toString()

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
