palava = @palava

# Channel implementation using websockets
#
# Events: open -> (), message -> (msg), error -> (), close -> ()
#
class palava.WebSocketChannel extends @EventEmitter

  # @param address [String] Address of the websocket. Should start with `ws://` for web sockets or `wss://` for secure web sockets.
  constructor: (address, retries = 2) ->
    @address = address
    @retries = retries
    @messagesToDeliverOnConnect = []
    @setupWebsocket()
    @startClientPings()

  # Returns true if socket is in a good state
  isConnected: =>
    @socket?.readyState == 1

  sendDeliverOnConnectMessages: =>
    for msg in @messagesToDeliverOnConnect
      @socket.send(msg)
    @messagesToDeliverOnConnect = []

  # Connects websocket events with the events of this object
  #
  # @nodoc
  #
  setupWebsocket: =>
    @socket = new WebSocket(@address)

    @socket.onopen = (handshake) =>
      @retries = 0
      @sendDeliverOnConnectMessages()
      @emit 'open', handshake

    @socket.onmessage = (msg) =>
      try
        parsedMsg = JSON.parse(msg.data)
      catch error
        @emit 'error', 'invalid_format',
          error: error,
          data: msg.data
        return

      if parsedMsg.event == "pong"
        @outstandingPongs = 0
      else
        @emit 'message', parsedMsg

    @socket.onerror = (msg) =>
      clearInterval(@pingInterval)
      if @retries > 0
        @retries -= 1
        @setupWebsocket()
        @startClientPings()
      else
        @emit 'error', 'socket', msg

    @socket.onclose = =>
      clearInterval(@pingInterval)
      @emit 'close'

  startClientPings: =>
    @outstandingPongs = 0
    @pingInterval = setInterval( () =>
      if @outstandingPongs >= 6
        clearInterval(@pingInterval)
        @socket.close()
        @emit 'error', "missing_pongs"

      @socket.send(JSON.stringify({event: "ping"}))
      @outstandingPongs += 1
    , 5000)

  # Sends the given data through the websocket
  #
  # @param data [Object] Object to send through the channel
  #
  send: (data) =>
    if @socket.readyState == 1 # successful connection
      if @messagesToDeliverOnConnect.length != 0
        @sendDeliverOnConnectMessages()
      @socket.send JSON.stringify(data)
    else if @socket.readyState > 1 # connection closing or closed
      @emit 'not_reachable'
    else # connection still to be established
      @messagesToDeliverOnConnect.push(JSON.stringify(data))

  # Closes the websocket
  #
  close: () =>
    @socket.close()
