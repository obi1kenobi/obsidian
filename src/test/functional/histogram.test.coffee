_                       = require('underscore')
should                  = require('chai').should()
{ histogram }           = require('../../lib/analysis/words')

describe 'Word histograms', () ->
  it 'should compute histograms with valid values', () ->
    make = (string, value) ->
      return {string, value}

    test_data = [
                  make 'a', 1
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

  it 'should compute histograms with words longer than 15 characters', () ->
    histogram.create('abcdefghijklmnop').should.equal 0x22222222

  it 'should subtract histograms correctly', () ->
    make = (hista, histb, answer) ->
      return {hista, histb, answer}

    test_data = [
                  make 0x1, 0x2, 1
                  make 0x10, 0x1, 2
                  make 0x401, 0x104, 6
                ]

    for item in test_data
      histogram.difference(item.hista, item.histb).should.equal item.answer
