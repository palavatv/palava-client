# export if module (CommonJS)
if typeof module == "object" and typeof module.exports == "object"
  module.exports = @palava

if typeof EventEmitter != "object" and typeof require == "function"
  @EventEmitter = require('wolfy87-eventemitter')

if typeof $ != "object" and typeof require == "function"
  @$ = require('jquery')
