#= require ./browser
#= require ./web_socket_channel

palava = @palava

# Session is a wrapper around a concrete room, channel and userMedia
class palava.Session extends @EventEmitter

  # @param o [Object] Options for the session
  # @option o channel [palava.Channel] A channel Object which will be used for communication
  # @option o web_socket_channel [WebSocket] A websocket from which a channel will be created
  # @option o identity [palava.Identity] TODO
  # @option o options [Object] TODO
  #
  constructor: (o) ->
    @resetOptions(o, false)

  # Reset all options to default parameters
  #
  # @param o          [Object]  See constructor for details
  # @param reconnect  [Boolean] Is part of a reconnect?
  #
  resetOptions: (o, reconnect = false) =>
    @channel     = null
    @userMedia   = null unless reconnect
    @roomId      = null
    @roomOptions = {}
    @assignOptions(o)
    @initOptions = o

  # Initializes the session
  #
  # @param o [Object] See constructor for details
  # @param reconnect  [Boolean] Is part of a reconnect?
  #
  init: (o, reconnect = false) =>
    @assignOptions(o)
    Object.assign(@initOptions, o)
    return unless @checkRequirements() unless reconnect
    @setupRoom()
    @userMedia.requestStream() unless reconnect

  # Moves options into inner state
  #
  # @nodoc
  #
  assignOptions: (o) =>
    @roomId = o.roomId || @roomId

    if o.web_socket_address
      @channel = new palava.WebSocketChannel(o.web_socket_address)

    if o.identity
      @userMedia = o.identity.newUserMedia()
      @roomOptions.ownStatus = o.identity.getStatus()

    if o.dataChannels
      @roomOptions.dataChannels = o.dataChannels

    if o.options
      @roomOptions.stun        = o.options.stun        || @roomOptions.stun
      @roomOptions.turn        = o.options.turn        || @roomOptions.turn
      @roomOptions.joinTimeout = o.options.joinTimeout || @roomOptions.joinTimeout

  # Checks whether the inner state of the session is valid. Emits events otherwise
  #
  # @return [Boolean] `true` if options are correct and webrtc support is given
  #
  checkRequirements: =>
    unless @channel
      @emit 'argument_error', 'no channel given'
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
    unless @roomOptions.stun
      @emit 'argument_error', 'no stun server given'
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

  # Maps signals from room to session signals
  #
  # @nodoc
  #
  setupRoom: => # TODO move some more stuff away from the room? eg signaling
    @room = new palava.Room @roomId, @channel, @userMedia, @roomOptions
    @room.on 'local_stream_ready',      (s) => @emit 'local_stream_ready', s
    @room.on 'local_stream_error',      (e) => @emit 'local_stream_error', e
    @room.on 'local_stream_removed',        => @emit 'local_stream_removed'
    @room.on 'join_error',              (e) => @emit 'room_join_error', @room, e
    @room.on 'full',                        => @emit 'room_full',       @room
    @room.on 'joined',                      => @emit 'room_joined',     @room
    @room.on 'peer_joined',             (p) => @emit 'peer_joined', p
    @room.on 'peer_offer',              (p) => @emit 'peer_offer', p
    @room.on 'peer_answer',             (p) => @emit 'peer_answer', p
    @room.on 'peer_update',             (p) => @emit 'peer_update', p
    @room.on 'peer_stream_ready',       (p) => @emit 'peer_stream_ready', p
    @room.on 'peer_stream_removed',     (p) => @emit 'peer_stream_removed', p
    @room.on 'peer_connection_pending',      (p) => @emit 'peer_connection_pending', p
    @room.on 'peer_connection_established',  (p) => @emit 'peer_connection_established', p
    @room.on 'peer_connection_failed',       (p) => @emit 'peer_connection_failed', p
    @room.on 'peer_connection_disconnected', (p) => @emit 'peer_connection_disconnected', p
    @room.on 'peer_connection_closed',       (p) => @emit 'peer_connection_closed', p
    @room.on 'peer_left',               (p) => @emit 'peer_left', p
    @room.on 'peer_channel_ready',      (p, n, c) => @emit 'peer_channel_ready', p, n, c
    @room.on 'signaling_shutdown',      (p) => @emit 'signaling_shutdown', p
    @room.on 'signaling_close',         (p) => @emit 'signaling_close', p
    @room.on 'signaling_error',         (p) => @emit 'signaling_error', p
    @room.on 'signaling_not_reachable',     => @emit 'signaling_not_reachable'
    true

  # Reconnect the session
  #
  reconnect: =>
    @emit 'session_reconnect'
    @destroy(true)
    @resetOptions(@initOptions, true)
    @init({}, true)

  # Destroys the session
  #
  # @param reconnect  [Boolean] Is part of a reconnect?
  #
  destroy: (reconnect = false) =>
    @emit 'session_before_destroy' unless reconnect
    @room      && @room.leave()
    @channel   && @channel.close()
    @userMedia && @userMedia.releaseStream() unless reconnect
    @emit 'session_after_destroy' unless reconnect
