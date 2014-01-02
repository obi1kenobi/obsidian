_             = require('underscore')
algorithm     = require('../../algorithm')

logDebug      = require('../../logging').logDebug('analysis::word::VPTree')

###
Vantage Point Tree data structure.

See explanation at http://stevehanov.ca/blog/index.php?id=130
###
class VPTree

  ###
  @param inputs  {Array} array of values to include in the VP tree
  @param metric  {function} distance metric between input objects f(a, b)
                            it has to be a proper metric, it must satisfy
                              f(a, a) = 0
                              f(a, b) >= 0 for all a, b
                              f(a, b) = f(b, a)
                              f(a, c) <= f(a, b) + f(b, c)
  ###
  constructor: (inputs, @metric) ->
    @data = ({value: x} for x in inputs)
    @root = @_buildFromPoints 0, @data.length
    @_tau = null
    @_closestOneResult = null

  _closestRecurse: (value, node_index) ->
    node = @data[node_index]
    dist = @metric value, node.value
    if dist < @_tau
      @_tau = dist
      @_closestOneResult = node

    if node.r?
      threshold = node.r
      if dist < threshold
        if node.left? and dist - @_tau <= threshold
          @_closestRecurse value, node.left
        if node.right? and dist + @_tau >= threshold
          @_closestRecurse value, node.right
      else
        if node.right? and dist + @_tau >= threshold
          @_closestRecurse value, node.right
        if node.left? and dist - @_tau <= threshold
          @_closestRecurse value, node.left

  ###
  @param value  {Object} an object that belongs in the metric space (can be compared by the metric)
  @return the closest object part of the VPTree, as defined by the metric
  ###
  closestOne: (value) ->
    @_tau = Number.POSITIVE_INFINITY
    @_closestOneResult = null
    @_closestRecurse value, @root
    return @_closestOneResult.value

  _buildFromPoints: (lo, hi) ->
    if lo == hi
      # no points in range
      return null
    if lo + 1 == hi
      # single point in range
      return lo
    # else, lo + 1 < hi

    # pick random local root
    local_root_index = _.random lo, hi - 1

    # move local root to front
    algorithm.swap @data, lo, local_root_index
    local_root_index = lo

    median_position = (hi - (lo + 1)) >> 1
    comparator = (a, b) =>
      return algorithm.numberComparator @metric(a.value, @data[local_root_index].value), @metric(b.value, @data[local_root_index].value)

    # partition around median element
    algorithm.nthElement @data, lo + 1, hi, median_position, comparator
    median_position += lo + 1

    base =
      r: @metric @data[local_root_index].value, @data[median_position].value
      left: @_buildFromPoints lo+1, median_position + 1
      right: @_buildFromPoints median_position + 1, hi

    _.extend @data[local_root_index], base

    return local_root_index

  _debugPrint: () ->
    logDebug "root: #{@root}"
    logDebug @data

module.exports = VPTree
