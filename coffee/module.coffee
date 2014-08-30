# export if module (CommonJS)
if typeof module == "object" and typeof module.exports == "object"
  module.exports = this

if typeof EventEmitter != "object" and typeof require == "function"
  @EventEmitter = require('wolfy87-eventemitter')
