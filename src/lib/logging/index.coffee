colors    = require('colors')
util      = require('util')

random_colors = ['yellow', 'cyan', 'magenta', 'green', 'blue', 'grey']

choose_random_color = () ->
  index = Math.floor(Math.random() * random_colors.length)
  return random_colors[index]

Logging =
  logDebug: (name) ->
    color = choose_random_color()
    name += ': '
    name = name.bold[color]
    return () ->
      util.print(name)
      console.log.apply(null, arguments)

  logError: (name) ->
    color = 'red'
    name += ': '
    name = name.bold[color]
    return () ->
      arguments[0] = name + arguments[0]
      console.error.apply(null, arguments)

module.exports = Logging
