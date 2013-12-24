fs        = require('fs')
path      = require('path')
async     = require('async')

Util =
  promiseToCallback: (promise, cb) ->
    promise.then () ->
      cb()
    , (err) ->
      cb(err)

  ###
  Collects all files at or below a given path that match a predicate.

  The predicate is a function (file_path) -> boolean.
  ###
  recursivelyCollectFiles: (start_path, predicate, cb) ->
    async.waterfall [
      (done) ->
        fs.readdir(start_path, done)
      (files, done) ->
        async.map files, (item, callback) ->
          full_path = path.resolve(start_path, item)
          if fs.lstatSync(full_path).isDirectory()
            Util.recursivelyCollectFiles full_path, predicate, callback
          else
            if predicate(full_path)
              callback(null, [full_path])
            else
              callback(null, [])
        , (err, res) ->
          if err?
            done(err)
          else
            done(null, [].concat.apply([], res))
    ], cb

  ###
  Calls Object.freeze on all keys recursively, instead of just freezing the top-level object.
  ###
  deepFreeze: (obj) ->
    for k, v of obj
      if typeof v == 'object'
        Util.deepFreeze v
    Object.freeze obj


module.exports = Util
