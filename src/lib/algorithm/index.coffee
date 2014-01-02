logDebug           = require('../logging').logDebug('algorithm')

Algorithm =

  ###
  Swaps the elements at the two specified indices in the array.

  @param array {Array} -- Mutated!
  @param a     {Integer}
  @param b     {Integer}
  ###
  swap: (array, a, b) ->
    tmp = array[a]
    array[a] = array[b]
    array[b] = tmp

  ###
  Compares two numbers, returning -1, 0 or 1 for <, = or > respectively.

  @param a  {Integer}
  @param b  {Integer}
  @return {Integer}
  ###
  numberComparator: (a, b) ->
    if a < b
      return -1
    else if a > b
      return 1
    else
      return 0

  ###
  Partitions the specified array fragment around the pivot index with the given comparator.

  @param array      {Array} -- Mutated (reordered)
  @param lo         {Integer} inclusive lower bound of the array fragment
  @param hi         {Integer} exclusive upper bound of the array fragment
  @param pivot      {Integer} pivot index to partition around
  @param comparator {function} comparator function that takes two array elements
                               and returns negative (<), 0 (=) or positive (>)
  @return {Integer} the new index of the pivot
  ###
  partition: (array, lo, hi, pivot, comparator) ->
    if pivot < lo or pivot >= hi
      throw new Error "Illegal pivot index, not in [#{lo},#{hi}): #{pivot}"

    pivot_val = array[pivot]
    if lo != pivot
      Algorithm.swap array, lo, pivot
      pivot = lo

    for i in [lo+1...hi]
      if comparator(array[i], pivot_val) <= 0
        Algorithm.swap array, i, pivot + 1
        Algorithm.swap array, pivot, pivot + 1
        pivot++

    return pivot

  ###
  Finds the n-th element in the specified array fragment with the given comparator.

  The n-th element is always at index lo + n in the array.

  @param array      {Array} -- Mutated (reordered)
  @param lo         {Integer} inclusive lower bound of the array fragment
  @param hi         {Integer} exclusive upper bound of the array fragment
  @param n          {Integer} 0-indexed number of element to find. Should be in [0, hi-lo)
  @param comparator {function} comparator function that takes two array elements
                               and returns negative (<), 0 (=) or positive (>)
  ###
  nthElement: (array, lo, hi, n, comparator) ->
    if n < 0 or n >= hi-lo
      throw new Error "Illegal n value, not in [0, #{hi-lo}): #{n}"

    if lo == hi
      return

    pivot = Algorithm.partition array, lo, hi, lo, comparator
    dist = n - (pivot - lo)
    if dist > 0
      # need more elements, search right part
      return Algorithm.nthElement array, pivot + 1, hi, dist - 1, comparator
    else if dist < 0
      # took too many elements, search left part
      return Algorithm.nthElement array, lo, pivot, n, comparator
    else
      # we got lucky and hit the nth element early, return
      return

module.exports = Algorithm
