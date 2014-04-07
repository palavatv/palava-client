# Channel implementation using websockets
#
# Events: open -> (), message -> (msg), error -> (), close -> ()
#
class palava.WebSocketChannel extends EventEmitter

  # @param address [String] Address of the websocket. Should start with `ws://` for web sockets or `wss://` for secure web sockets.
  constructor: (address) ->
    @reached      = false
    @socket       = new WebSocket(address)#, [palava.protocol_identifier()])
    @socket.onopen = (handshake) =>
      @setupEvents()
      @emit 'open', handshake

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
    @send_or_retry(data, 3)

  # Sends given data, if connection is established
  # Otherwise retry 'retries' times and emit a not_reachable error in the end
  #
  # @param data [Object] Object to send through the channel
  # @param retries [Integer] Number of retries
  #
  send_or_retry: (data, retries) =>
    if countdown == 0
      @emit 'not_reachable', @serverAddress
    else if @reached || @socket.readyState != 3
      @reached = true
      @socket.send JSON.stringify(data)
    else
      setTimeout (=>
        send_or_retry(data, retries - 1)
      ), 400

  # Closes the websocket
  #
  close: () =>
    @socket.close()
