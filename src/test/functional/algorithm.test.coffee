_                       = require('underscore')
should                  = require('chai').should()
algorithm               = require('../../lib/algorithm')

describe 'Algorithm', () ->
  describe 'swap', () ->
    it 'should swap different values', () ->
      array = [0, 1, 2, 3, 4]
      algorithm.swap array, 3, 2
      array.should.eql [0, 1, 3, 2, 4]
      algorithm.swap array, 3, 2
      array.should.eql [0, 1, 2, 3, 4]

    it 'swapping on the same index is a no-op', () ->
      array = [0, 1, 2, 3, 4]
      algorithm.swap array, 1, 1
      array.should.eql [0, 1, 2, 3, 4]

  describe 'partition', () ->
    it 'should partition the full array', () ->
      array = [2, 4, 1, 0, 3]
      pivot = algorithm.partition array, 0, 4, 0, algorithm.numberComparator
      pivot.should.equal 2

      for i in [0...2]
        array[i].should.be.below array[pivot] + 1
      for i in [3...5]
        array[i].should.be.above array[pivot] - 1

    it 'should partition fragments of the array', () ->
      array = [-1, -1, 2, 4, 1, 0, 3, -1, -1]
      pivot = algorithm.partition array, 2, 6, 2, algorithm.numberComparator
      pivot.should.equal 4

      for i in [0...2]
        array[i].should.equal -1
      for i in [2...5]
        array[i].should.be.below array[pivot] + 1
      for i in [5...7]
        array[i].should.be.above array[pivot] - 1
      for i in [7...9]
        array[i].should.equal -1

  describe 'nth element', () ->
    it 'should find the nth element in the full array', () ->
      array = _.shuffle [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
      algorithm.nthElement array, 0, array.length, 5, algorithm.numberComparator
      array[5].should.equal 5
      for i in [0...5]
        array[i].should.be.below 6
      for i in [5...array.length]
        array[i].should.be.above 4

    it 'should find the nth element in a fragment of the array', () ->
      array = _.shuffle [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

      array.push -1
      array.unshift -1
      algorithm.nthElement array, 1, array.length - 1, 5, algorithm.numberComparator
      array[6].should.equal 5
      for i in [1...6]
        array[i].should.be.below 6
      for i in [6...array.length-1]
        array[i].should.be.above 4
      array[0].should.equal -1
      array[array.length-1].should.equal -1
