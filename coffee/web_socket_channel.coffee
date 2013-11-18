# Channel implementation for websockets
# Events: open -> (), message -> (msg), error -> (), close -> ()
class WebSocketChannel extends EventEmitter
  constructor: (address) ->
    @reached      = false
    @socket       = new WebSocket(address)#, [palava.protocol_identifier()])
    @socket.onopen = (handshake) =>
      @setupEvents()
      @emit 'open', handshake

  setupEvents: =>
    @socket.onmessage = (msg) =>
      try
        @emit 'message', JSON.parse(msg.data)
      catch SyntaxError
        @emit 'error_invalid_json', msg
    @socket.onerror = (msg) =>
      @emit 'error', msg
    @socket.onclose = =>
      @emit 'close'

  send: (data) =>
    @socket.send JSON.stringify(data)
    unless @reached
      @checkConnectionTimeout()

  close: () =>
    @socket.close()

  checkConnectionTimeout: =>
    setTimeout ( =>
      if @socket.readyState == 3
        @emit 'not_reachable', @serverAddress
      else
        @reached = true
    ), 500

namespace 'palava', (exports) ->
  exports.WebSocketChannel = WebSocketChannel
