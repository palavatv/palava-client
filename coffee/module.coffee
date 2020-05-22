# export if module (CommonJS)
if typeof module == "object" and typeof module.exports == "object"
  module.exports = @palava

if typeof EventEmitter != "object" and typeof require == "function"
  @EventEmitter = require('wolfy87-eventemitter')
else
  @EventEmitter = EventEmitter

if typeof adapter != "object" and typeof require == "function"
  @adapter = require('webrtc-adapter/out/adapter_no_edge')
else
  @adapter = adapter
