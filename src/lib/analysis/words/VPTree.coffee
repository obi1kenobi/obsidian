_             = require('underscore')
algorithm     = require('../../algorithm')

logDebug      = require('../../logging').logDebug('analysis::word::VPTree')

###
Vantage Point Tree data structure.

See explanation at http://stevehanov.ca/blog/index.php?id=130
###
class VPTree

  ###
  @param inputs  {Array} array of {key, value} objects
  @param metric  {function} distance metric between input objects f(a, b)
                            it has to be a proper metric, it must satisfy
                              f(a, a) = 0
                              f(a, b) >= 0 for all a, b
                              f(a, b) = f(b, a)
                              f(a, c) <= f(a, b) + f(b, c)
  ###
  constructor: (inputs, @metric) ->
    @data = inputs.slice(0)  # make a copy of the data
    @root = @_buildFromPoints 0, @data.length

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
      return algorithm.numberComparator @metric(a, @data[local_root_index]), @metric(b, @data[local_root_index])

    # partition around median element
    algorithm.nthElement @data, lo + 1, hi, median_position, comparator
    median_position += lo + 1

    base =
      r: @metric @data[local_root_index], @data[median_position]
      left: @_buildFromPoints lo+1, median_position + 1
      right: @_buildFromPoints median_position + 1, hi

    _.extend @data[local_root_index], base

    return local_root_index

  _debugPrint: () ->
    logDebug "root: #{@root}"
    logDebug @data

module.exports = VPTree
