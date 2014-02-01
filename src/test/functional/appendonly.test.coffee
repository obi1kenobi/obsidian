_                       = require('underscore')
should                  = require('chai').should()
appendonly              = require('../../lib/appendonly')

describe 'Append-only', () ->
  testObject =
    string: 'abc'
    newlines: 'def\nghi'
    empty: ''
    nulled: null
    arr: [1, 2, 3]
    num: 3.14

  it 'serializes and parses a full entry', () ->
    expected =
      entries: [testObject]
      remainder: ''

    entry = appendonly.serialize expected.entries[0]
    result = appendonly.parse entry
    should.exist result
    result.should.eql expected

  it 'serializes and parses sets of entries', () ->
    expected =
      entries: [testObject, testObject, {}]
      remainder: ''

    entries = (appendonly.serialize(e) for e in expected.entries)
    result = appendonly.parse entries.join('')
    should.exist result
    result.should.eql expected

  it 'processes incomplete entries', () ->
    e = appendonly.serialize(testObject)
    e = e.substr(0, e.length-1)

    expected =
      entries: [testObject, {}]
      remainder: e
    entries = (appendonly.serialize(e) for e in expected.entries)
    entries.push expected.remainder
    result = appendonly.parse entries.join('')
    should.exist result
    result.should.eql expected
