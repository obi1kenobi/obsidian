should                  = require('chai').should()
redis                   = require('../../lib/connections/redis')

logDebug                = require('../../lib/logging').logDebug('redis::test')

describe 'Redis connection', () ->
  before (done) ->
    redis.initialize done

  it 'should connect and process commands', (done) ->
    key = "test-key"
    value = "test-value"

    redis.client.set key, value, (err, res) ->
      should.not.exist err
      redis.client.get key, (err, res) ->
        should.not.exist err
        should.exist res
        res.should.equal value
        done()
