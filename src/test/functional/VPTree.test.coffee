_             = require('underscore')
should        = require('chai').should()
{ VPTree }    = require('../../lib/analysis/words')

logDebug      = require('../../lib/logging').logDebug('test::VPTree')

describe 'VPTree', () ->
  metric = (a, b) ->
    return Math.abs(a.key-b.key)

  make = (key, value) ->
    return {key, value}

  it 'should be connected and have valid radii', () ->
    data = _.shuffle [
      make 0, 0
      make 1, 1
      make 2, 2
      make 3, 3
      make 4, 4
      make 5, 5
      make 6, 6
    ]

    vpt = new VPTree data, metric
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
