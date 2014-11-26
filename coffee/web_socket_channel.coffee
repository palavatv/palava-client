palava = @palava

# Channel implementation using websockets
#
# Events: open -> (), message -> (msg), error -> (), close -> ()
#
class palava.WebSocketChannel extends @EventEmitter

  # @param address [String] Address of the websocket. Should start with `ws://` for web sockets or `wss://` for secure web sockets.
  constructor: (address) ->
    @reached      = false
    @socket       = new WebSocket(address)#, [palava.protocol_identifier()])
    @messagesToDeliverOnConnect = []
    @socket.onopen = (handshake) =>
      @setupEvents()
      @sendMessages()
      @emit 'open', handshake

  sendMessages: =>
    for msg in @messagesToDeliverOnConnect
      @socket.send(msg)
    @messagesToDeliverOnConnect = []

  # Connects websocket events with the events of this object
  #
  # @nodoc
  #
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

  # Sends the given data through the websocket
  #
  # @param data [Object] Object to send through the channel
  #
  send: (data) =>
    if @socket.readyState == 1 # reached
      if @messagesToDeliverOnConnect.length != 0
        @sendMessages()
      @socket.send JSON.stringify(data)
    else if @socket.readyState > 1 # closing or closed
      @emit 'not_reachable', @serverAddress
    else # connecting ...
      if @messagesToDeliverOnConnect.length == 0
        setTimeout (=>
          if @socket.readyState != 1
            @close()
            @emit 'not_reachable', @serverAddress
        ), 5000
      @messagesToDeliverOnConnect.push(JSON.stringify(data))

  # Closes the websocket
  #
  close: () =>
    @socket.close()
