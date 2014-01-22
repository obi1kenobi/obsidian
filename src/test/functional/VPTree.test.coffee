_             = require('underscore')
should        = require('chai').should()
{ VPTree }    = require('../../lib/analysis/words')

logDebug      = require('../../lib/logging').logDebug('test::VPTree')

describe 'VPTree', () ->
  metric = (a, b) ->
    return Math.abs(a-b)

  data = _.shuffle [0, 1, 2, 3, 4, 5, 6]

  it 'should be connected and have valid radii', () ->
    vpt = new VPTree(data, metric)
    connected = [vpt.root]
    _.each vpt.data, (element) ->
      connected.push element.left if element?.left?
      connected.push element.right if element?.right?

    connected.sort()
    connected.should.eql [0...data.length]

    iterateNodeAndChildren = (node, iter) ->
      iter(node)
      if node.left?
        iterateNodeAndChildren node.left, iter
      if node.right?
        iterateNodeAndChildren node.right, iter

    validateRadii = (node) ->
      if node.r?
        iterateNodeAndChildren node.left, (elem) ->
          metric(elem, node).should.not.be.above node.r
        iterateNodeAndChildren node.right, (elem) ->
          metric(elem, node).should.not.be.below node.r

    validateRadii vpt.root

  it 'should find the closest element', () ->
    vpt = new VPTree(data, metric)
    result = vpt.closestOne 2.1
    should.exist result
    result.should.eql 2

    result = vpt.closestOne -0.1
    should.exist result
    result.should.eql 0

    result = vpt.closestOne 6.1
    should.exist result
    result.should.eql 6
