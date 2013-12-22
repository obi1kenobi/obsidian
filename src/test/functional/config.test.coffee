should = require('chai').should()

config = require('../../lib/config')

describe 'Check config loading', () ->
  it 'should load correctly', () ->
    should.exist(config.test_value)
    config.test_value.should.equal(true)
