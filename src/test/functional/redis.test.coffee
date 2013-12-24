should                  = require('chai').should()
redis                   = require('../../lib/connections/redis')
{ constants }           = require('../../lib/common')
logDebug                = require('../../lib/logging').logDebug('redis::test')

describe 'Redis connection', () ->
  before (done) ->
    redis.initialize done

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
    value = "test-key-2"

    sha = redis.scriptShas[constants.REDIS_SCRIPTS.SET_ALIAS_TEST]
    redis.client.evalsha sha, 1, key, value, (err, res) ->
      should.not.exist err
      redis.client.get key, (err, res) ->
        should.not.exist err
        should.exist res
        res.should.equal value
        done()
