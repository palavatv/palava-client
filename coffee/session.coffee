#= require ./browser
#= require ./web_socket_channel

palava = @palava

# Session is a wrapper around a concrete room, channel and userMedia
class palava.Session extends @EventEmitter
  # Creates the session object
  #
  # @param o [Object] See Session#connect for available options
  #
  constructor: (o) ->
    @roomOptions = {}
    @assignOptions(o)

  # Initializes the websocket channel, retrieves user media and joins room when stream ready
  #
  # @param o [Object] Options for the session
  # @option o webSocketAddress [WebSocket] The websocket endpoint to connect to
  # @option o userMediaConfig [Object] getUserMedia constraints
  # @option o stun [String] Address of stun server
  # @option o turn [String] Turn address and credentials
  # @option o joinTimeout [Integer] Milliseconds till joining is canceled by throwing
  #           the "join_error" event
  #
  connect: (o) =>
    @assignOptions(o)
    return unless @checkRequirements()

    @createChannel()
    @createRoom()

    if @userMedia.stream
      @room.join()
    else
      @userMedia.requestStream().then =>
        @room.join()

  # Reconnect the session
  #
  reconnect: =>
    @emit 'session_reconnect'
    @tearDown()
    @createChannel()
    @createRoom()
    @room.join()

  # Reset channel and room
  #
  # @param o [Object] Also release user media
  #
  tearDown: (resetUserMedia = false) =>
    @room?.removeAllListeners()
    @channel?.removeAllListeners()
    if @channel?.isConnected()
      @room?.leave()
    @channel?.close()
    @channel = null
    @room?.destroy()
    @room = null
    if resetUserMedia && @userMedia
      @userMedia.releaseStream()

  # Moves options into inner state
  #
  # @nodoc
  #
  assignOptions: (o) =>
    if o.roomId
      @roomId = o.roomId

    if o.webSocketAddress
      @webSocketAddress = o.webSocketAddress

    if o.identity
      @userMedia = o.identity.newUserMedia()
      @roomOptions.ownStatus = o.identity.getStatus()

    if o.userMediaConfig
      @userMedia = new palava.Gum(o.userMediaConfig)

    if o.dataChannels
      @roomOptions.dataChannels = o.dataChannels

    if o.stun
      @roomOptions.stun = o.stun

    if o.turn
      @roomOptions.turn = o.turn

    if o.joinTimeout
      @roomOptions.joinTimeout = o.joinTimeout

  # Checks whether the inner state of the session is valid. Emits events otherwise
  #
  # @return [Boolean] `true` if options are correct and webrtc support is given
  #
  checkRequirements: =>
    unless @webSocketAddress
      @emit 'argument_error', 'no web socket address given'
      return false
    unless @userMedia
      @emit 'argument_error', 'no user media given'
      return false
    unless @roomId
      @emit 'argument_error', 'no room id given'
      return false
    unless @roomOptions.stun
      @emit 'argument_error', 'no stun server given'
      return false
    unless navigator.onLine
      @emit 'signaling_not_reachable'
      return false
    if e = palava.browser.checkForWebrtcError()
      @emit 'webrtc_no_support', 'WebRTC is not supported by your browser', e
      return false
    true

  # Get the channel of the session
  #
  # @return [palava.Channel] The channel of the session
  #
  getChannel:   => @channel

  # Get the UserMedia of the session
  #
  # @return [UserMedia] UserMedia of the session
  #
  getUserMedia: => @userMedia

  # Get the room of the session
  #
  # @return [palava.Room] Room of the session
  #
  getRoom:      => @room

  # Build connection to websocket endpont
  #
  # @return [palava.Room] Room of the session
  #
  createChannel: =>
    @channel = new palava.WebSocketChannel(@webSocketAddress)
    @channel.on 'open',              => @emit 'signaling_open'
    @channel.on 'error',      (t, e) => @emit 'signaling_error', t, e
    @channel.on 'close',         (e) => @emit 'signaling_close', e
    @channel.on 'not_reachable',     => @emit 'signaling_not_reachable'

  # Maps signals from room to session signals
  #
  # @nodoc
  #
  createRoom: => # TODO move some more stuff away from the room? eg signaling
    @room = new palava.Room @roomId, @channel, @userMedia, @roomOptions
    @room.on 'local_stream_ready',      (s) => @emit 'local_stream_ready', s
    @room.on 'local_stream_error',      (e) => @emit 'local_stream_error', e
    @room.on 'local_stream_removed',        => @emit 'local_stream_removed'
    @room.on 'join_error',                  =>
      @tearDown(true)
      @emit 'room_join_error', @room
    @room.on 'full',                        => @emit 'room_full',       @room
    @room.on 'joined',               (u, p) =>
      @turnCredentials =
        user: tu
        password: tpw
      @emit 'room_joined', @room
    @room.on 'left',                        => @emit 'room_left',       @room
    @room.on 'peer_joined',             (p) => @emit 'peer_joined', p
    @room.on 'peer_offer',              (p) => @emit 'peer_offer', p
    @room.on 'peer_answer',             (p) => @emit 'peer_answer', p
    @room.on 'peer_update',             (p) => @emit 'peer_update', p
    @room.on 'peer_stream_ready',       (p) => @emit 'peer_stream_ready', p
    @room.on 'peer_stream_removed',     (p) => @emit 'peer_stream_removed', p
    @room.on 'peer_connection_pending',      (p) => @emit 'peer_connection_pending', p
    @room.on 'peer_connection_established',  (p) => @emit 'peer_connection_established', p
    @room.on 'peer_connection_failed',       (p) =>
      if !p.hasTriedTurn && @turnCredentials
        p.tryTurn @turnCredentials
      else
        @emit 'peer_connection_failed', p
    @room.on 'peer_connection_disconnected', (p) => @emit 'peer_connection_disconnected', p
    @room.on 'peer_connection_closed',       (p) => @emit 'peer_connection_closed', p
    @room.on 'peer_left',               (p) => @emit 'peer_left', p
    @room.on 'peer_channel_ready',      (p, n, c) => @emit 'peer_channel_ready', p, n, c
    @room.on 'signaling_shutdown',      (p) => @emit 'signaling_shutdown', p
    @room.on 'signaling_error',      (t, e) => @emit 'signaling_error', t, e
    true

  # Destroys the session
  destroy: =>
    @emit 'session_before_destroy'
    @tearDown(true)
    @emit 'session_after_destroy'
