chai = require('chai')
chai.should() # init chai

describe.skip 'Make sure sure mocha and chai work', () ->
  it 'should work without a callback', () ->
    text = 'abc'
    text.should.have.length(3)
    text.should.equal('abc')
  it 'should work with a callback', (done) ->
    text = 'abc'
    text.should.have.length(3)
    text.should.equal('abc')
    done()
