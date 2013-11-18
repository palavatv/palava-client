#= require ./browser
#= require ./web_socket_channel

# Session is a wrapper around a concrete room + channel + userMedia

class Session extends EventEmitter
  constructor: (o) ->
    @channel     = null
    @userMedia   = null
    @roomId      = null
    @roomOptions = {}
    @assignOptions(o)

  init: (o) =>
    @assignOptions(o)
    @checkRequirements()
    @setupRoom()
    @userMedia.requestStream()

  assignOptions: (o) =>
    @roomId = o.roomId || @roomId

    if o.channel
      @channel = o.channel
    else if o.web_socket_channel
      @channel = new palava.WebSocketChannel(o.web_socket_channel)

    if o.identity
      @userMedia = o.identity.newUserMedia()
      @roomOptions.ownStatus = { name: o.identity.getName() }

    if o.options
      @roomOptions.stun        = o.options.stun        || @roomOptions.stun
      @roomOptions.joinTimeout = o.options.joinTimeout || @roomOptions.joinTimeout

  checkRequirements: =>
    unless @channel
      @emit 'argument_error', 'no channel given'
      return
    unless @userMedia
      @emit 'argument_error', 'no user media given'
      return
    unless @roomId
      @emit 'argument_error', 'no room id given'
      return
    unless @roomOptions.stun
      @emit 'argument_error', 'no stun server given'
      return
    if e = palava.browser.checkForWebrtcError()
      @emit 'webrtc_no_support', 'WebRTC is not supported by your browser', e
      return
    if palava.browser.checkForPartialSupport()
      @emit 'webrtc_partial_support'

  getChannel:   => @channel
  getUserMedia: => @userMedia
  getRoom:      => @room

  setupRoom: => # TODO move some more stuff away from the room? eg signaling
    @room = new palava.Room @roomId, @channel, @userMedia, @roomOptions
    @room.on 'local_stream_ready',      (s) => @emit 'local_stream_ready', s
    @room.on 'local_stream_error',      (s) => @emit 'local_stream_error'
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
    @room.on 'peer_left',               (p) => @emit 'peer_left', p
    @room.on 'signaling_shutdown',      (p) => @emit 'signaling_shutdown', p
    @room.on 'signaling_close',         (p) => @emit 'signaling_close', p
    @room.on 'signaling_error',         (p) => @emit 'signaling_error', p
    @room.on 'signaling_not_reachable', (p) => @emit 'signaling_not_reachable', p
    true

  destroy: =>
    @emit 'session_before_destroy'
    # @removeListeners() # TODO do we want to remove all listeners? not working
    @room      && @room.leave()
    @channel   && @channel.close()
    @userMedia && @userMedia.releaseStream()
    @emit 'session_after_destroy'

namespace 'palava', (exports) ->
  exports.Session = Session
