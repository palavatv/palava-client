#= require ./license
#= require ./namespace
#= require ./module
#= require ./browser
#= require ./identity
#= require ./room
#= require ./session

palava = @palava

palava.PROTOCOL_NAME = 'palava'
palava.PROTOCOL_VERSION = '1.0.0'

palava.protocol_identifier = ->
  # palava.PROTOCOL_NAME + '.' + parseFloat(exports.PROTOCOL_VERSION)
  palava.PROTOCOL_NAME = "palava.1.0"
