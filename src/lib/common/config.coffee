fs = require('fs')

readConfig = () ->
  return JSON.parse( fs.readFileSync(__dirname + '/../../../configs/default.json', { encoding: 'utf8' }) )

module.exports = Object.freeze(readConfig())
