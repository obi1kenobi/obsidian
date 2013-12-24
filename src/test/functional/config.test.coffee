should = require('chai').should()

{ config, constants } = require('../../lib/common')

describe 'Check config loading', () ->
  it 'should load correctly', () ->
    should.exist config.test_value
    config.test_value.should.equal true

  it 'should be immutable', () ->
    correct = false
    try
      # the following assignment should have no effect or throw an error
      config.test_value = false
      correct = config.test_value
    catch error
      correct = true
    correct.should.equal true

describe 'Check constants', () ->
  it 'should be immutable', () ->
    correct = false
    try
      oldval = constants.EXCHANGES.TEST_EXCHANGE

      # the following assignment should have no effect or throw an error
      constants.EXCHANGES.TEST_EXCHANGE = ''
      correct = (constants.EXCHANGES.TEST_EXCHANGE != '')

      console.log 'exchange:', constants.EXCHANGES.TEST_EXCHANGE

      constants.EXCHANGES.TEST_EXCHANGE = oldval
    catch error
      correct = true
    correct.should.equal true
