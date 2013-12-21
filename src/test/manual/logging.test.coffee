logging = require('../../lib/logging')

describe.skip 'Logging functionality', () ->
  describe 'logDebug', () ->
    logDebug = logging.logDebug('debug')

    it 'should choose a random color for each source', () ->
      debug_one = logging.logDebug('source_one')
      debug_two = logging.logDebug('source_two')

      debug_one 'Hello world!'
      debug_two 'Hi there!'

    it 'should obey format strings', () ->
      logDebug 'five = %d', 5

    it 'should pretty-print arrays', () ->
      logDebug 'as easy as =', [1, 2, 3]

    it 'should pretty-print objects', () ->
      logDebug 'object =', { a: 5, b: [1, 2], c: 'hi\n'}

  describe 'logError', () ->
    logError = logging.logError('error')

    it 'should work with plain strings', () ->
      logError 'Hello world!'

    it 'should obey format strings', () ->
      logError 'five = %d', 5

    it 'should pretty-print arrays', () ->
      logError 'as easy as =', [1, 2, 3]

    it 'should pretty-print objects', () ->
      logError 'object =', { a: 5, b: [1, 2], c: 'hi\n'}
