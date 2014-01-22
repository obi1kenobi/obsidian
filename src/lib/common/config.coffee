fs = require('fs')

readConfig = () ->
  file = __dirname + '/../../../configs/default.json'
  return JSON.parse( fs.readFileSync(file, { encoding: 'utf8' }) )

module.exports = readConfig()
