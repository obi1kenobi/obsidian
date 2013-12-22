should = require('chai').should()

{ config } = require('../../lib/common')

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
