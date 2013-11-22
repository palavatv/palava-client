#= require ./license
#= require ./namespace
#= require ./browser
#= require ./identity
#= require ./room
#= require ./session

namespace 'palava', (exports) ->
  exports.PROTOCOL_NAME = 'palava'
  exports.PROTOCOL_VERSION = '1.0.0'

  exports.protocol_identifier = ->
    # exports.PROTOCOL_NAME + '.' + parseFloat(exports.PROTOCOL_VERSION)
    exports.PROTOCOL_NAME = "palava.1.0"
