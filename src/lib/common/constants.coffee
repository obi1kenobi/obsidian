Constants =
  EXCHANGES:
    LINE_EXCHANGE: 'obsidian.lineExchange'
    TEST_EXCHANGE: 'obsidian.testExchange'
    CHUNK_EXCHANGE: 'obsidian.chunkExchange'

  QUEUES:
    LINE_QUEUE: 'obsidian.lineQueue'
    TEST_QUEUE: 'obsidian.testQueue'
    CHUNK_QUEUE: 'obsidian.chunkQueue'

  REDIS_SCRIPTS:
    BATCH_INCREMENT: 'BATCH_INCREMENT'
    SET_ALIAS_TEST: 'SET_ALIAS_TEST'

  REDIS_SCRIPT_FILES:
    'batch_increment.lua': 'BATCH_INCREMENT'
    'set_alias.test.lua': 'SET_ALIAS_TEST'

  LETTERS: [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
             'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
             'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
             'y', 'z', '-', "'",
             '^', '$'  # start and end of word tags
           ]

module.exports = Constants
