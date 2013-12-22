Util =
  promise_to_callback: (promise, cb) ->
    promise.then () ->
      cb()
    , (err) ->
      cb(err)

module.exports = Util
