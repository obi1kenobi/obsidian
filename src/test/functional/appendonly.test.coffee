_                           = require('underscore')
async                       = require('async')
chai                        = require('chai')
temp                        = require('temp')
{ serializer, hyperfile }   = require('../../lib/appendonly')

chai.use(require('chai-things'))
should = chai.should()
temp.track()  # track temporary files and delete them on exit

describe 'Append-only', () ->
  generateTestObject = () ->
    testObject =
      string: 'abc'
      newlines: 'def\nghi'
      empty: ''
      nulled: null
      arr: [1, 2, 3]
      num: 3.14
      rand: Math.random()

  describe 'Serializer', () ->
    it 'serializes and parses a full entry', () ->
      expected =
        entries: [generateTestObject()]
        remainder: ''

      entry = serializer.serialize expected.entries[0]
      result = serializer.parse entry
      should.exist result
      result.should.eql expected

    it 'serializes and parses sets of entries', () ->
      expected =
        entries: [generateTestObject(), generateTestObject(), {}]
        remainder: ''

      entries = (serializer.serialize(e) for e in expected.entries)
      result = serializer.parse entries.join('')
      should.exist result
      result.should.eql expected

    it 'processes incomplete entries', () ->
      e = serializer.serialize(generateTestObject())
      e = e.substr(0, e.length-1)

      expected =
        entries: [generateTestObject(), {}]
        remainder: e
      entries = (serializer.serialize(e) for e in expected.entries)
      entries.push expected.remainder
      result = serializer.parse entries.join('')
      should.exist result
      result.should.eql expected

  describe 'Hyperfile', () ->
    testPath = null

    beforeEach () ->
      testPath = temp.mkdirSync 'hyperfile'

    runTest = (err, writer, cb) ->
      expectedData = [generateTestObject(), {}, generateTestObject(), generateTestObject()]
      should.not.exist err  # this error would be generated on writer creation
      should.exist writer
      async.each expectedData, (item, callback) ->
        writer.write item, callback
      , (err, res) ->
        should.not.exist err
        returnedData = []
        iterator = (entry, callback) ->
          returnedData.push entry
          callback()
        hyperfile.readEntries testPath, iterator, (err, res) ->
          should.not.exist err
          for x in expectedData
            returnedData.should.include.something.that.deep.equals x
          cb()

    it 'writes and reads all entries when in a single file', (cb) ->
      hyperfile.createWriter testPath, (err, writer) ->
        runTest err, writer, cb

    it 'writes and reads all entries when in multiple files', (cb) ->
      hintSize = 10
      hyperfile.createWriter testPath, hintSize, (err, writer) ->
        runTest err, writer, cb
