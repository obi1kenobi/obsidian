_                       = require('underscore')
should                  = require('chai').should()
{ serializer }          = require('../../lib/appendonly')

describe 'Append-only', () ->
  describe 'Serializer', () ->
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

      entry = serializer.serialize expected.entries[0]
      result = serializer.parse entry
      should.exist result
      result.should.eql expected

    it 'serializes and parses sets of entries', () ->
      expected =
        entries: [testObject, testObject, {}]
        remainder: ''

      entries = (serializer.serialize(e) for e in expected.entries)
      result = serializer.parse entries.join('')
      should.exist result
      result.should.eql expected

    it 'processes incomplete entries', () ->
      e = serializer.serialize(testObject)
      e = e.substr(0, e.length-1)

      expected =
        entries: [testObject, {}]
        remainder: e
      entries = (serializer.serialize(e) for e in expected.entries)
      entries.push expected.remainder
      result = serializer.parse entries.join('')
      should.exist result
      result.should.eql expected
