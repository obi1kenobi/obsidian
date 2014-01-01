_                       = require('underscore')
should                  = require('chai').should()
{ histogram }           = require('../../lib/analysis/words')

describe 'Word histograms', () ->
  it 'should compute histograms with valid values', () ->
    make = (string, value) ->
      return {string, value}

    test_data = [ make 'a', 1
                  make 'b', 1 << 4
                  make 'c', 1 << 8
                  make 'd', 1 << 12
                  make 'e', 1 << 16
                  make 'f', 1 << 20
                  make 'g', 1 << 24
                  make 'h', 1 << 28
                  make 'abcdefgh', 0x11111111
                  make 'iiiiij', 0x15
                  make "cks-dlt'", 0x4400
                ]

    for item in test_data
      histogram.create(item.string).should.equal item.value

  it 'should throw errors on words longer than 15 characters', () ->
    fn = () -> histogram.create('abcdefghijklmnop')
    should.Throw fn, Error