_                       = require('underscore')
should                  = require('chai').should()
parse                   = require('../../lib/parser')

describe 'Parser', () ->
  runTest = (chunk, expected) ->
    result = parse(chunk)
    should.exist result
    result.should.eql expected

  SEPARATORS = '`!,.:;"?/\|[]{}()*&<>'

  ILLEGAL = '@#$%^0123456789_=+'

  it 'splits on and removes separators', () ->
    char = 'a'
    chunk = [char]
    expected = [char]
    for c in SEPARATORS
      chunk.push c
      chunk.push char
      expected.push char
    chunk = chunk.join ''
    runTest(chunk, expected)

  it 'splits on and removes words with illegal chars', () ->
    validWord = 'a'
    illegalWordChar = 'b'
    chunk = [validWord]
    expected = [validWord]
    for c in ILLEGAL
      chunk.push illegalWordChar + c + illegalWordChar
      chunk.push validWord
      expected.push validWord
    chunk = chunk.join ' '
    runTest(chunk, expected)

  it 'splits on and removes words with non-word chars', () ->
    chunk = 'abc sd\u2603df bca'
    expected = ['abc', 'bca']
    runTest(chunk, expected)

  it 'removes multiple whitespace', () ->
    chunk = 'abc  \t\r\ndef'
    expected = ['abc def']
    runTest(chunk, expected)

  it 'breaks up sentences before removing whitespace', () ->
    chunk = 'abc def. \r\nbcd  \tefg'
    expected = ['abc def', 'bcd efg']
    runTest(chunk, expected)

  it 'doesn\'t return empty entries', () ->
    chunk = SEPARATORS.substr(0)
    expected = []
    runTest(chunk, expected)

  it 'lowercases all results', () ->
    chunk = 'Abc def ghi.\nHello world!'
    expected = ['abc def ghi', 'hello world']
    runTest(chunk, expected)
