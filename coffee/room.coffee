#= require ./local_peer
#= require ./remote_peer
#= require ./gum
#= require ./distributor

palava = @palava

# A room connecting multiple participants
#
class palava.Room extends @EventEmitter

  # @param roomId [String] ID of the room
  # @param channel [palava.Channel] Channel used for communication
  # @param userMedia [UserMedia] UserMedia used for local user
  # @param options [Object] Further objects for the room
  # @option options joinTimeout [Integer] Timeout for joining
  # @option options ownStatus [Object] The status of the local user
  #
  constructor: (roomId, channel, userMedia, options = {}) ->
    @id        = roomId
    @userMedia = userMedia
    @channel   = channel
    @peers   = {}
    @options   = options

    @setupUserMedia()
    @setupDistributor()
    @setupOptions()

  # Bind UserMedia events to room events
  #
  # @nodoc
  #
  setupUserMedia: =>
    @userMedia.on 'stream_ready', (stream) => @emit 'local_stream_ready', stream
    @userMedia.on 'stream_error', (error)  => @emit 'local_stream_error', error
    @userMedia.on 'stream_released',       => @emit 'local_stream_removed'


  # Set default options
  #
  # @nodoc
  #
  setupOptions: =>
    @options.joinTimeout ||= 1000
    @options.ownStatus ||= {}

  # Initialize global distributor and messaging
  #
  # @nodoc
  #
  setupDistributor: =>
    @distributor = new palava.Distributor(@channel)

    @distributor.on 'joined_room', (msg) =>
      clearTimeout(@joinCheckTimeout)
      new palava.LocalPeer(msg.own_id, @options.ownStatus, @)
      for peer in msg.peers
        offers = !palava.browser.isChrome()
        newPeer = new palava.RemotePeer(peer.peer_id, peer.status, @, offers)
      @emit "joined", msg.own_id, msg.turn_user, msg.turn_password

    @distributor.on 'new_peer', (msg) =>
      offers = msg.status.user_agent == 'chrome'
      newPeer = new palava.RemotePeer(msg.peer_id, msg.status, @, offers)
      @emit 'peer_joined', newPeer

    @distributor.on 'error',    (msg) => @emit 'signaling_error', 'server', msg.description

    @distributor.on 'shutdown', (msg) => @emit 'signaling_shutdown', msg.seconds

  # Join the room
  #
  # @param status [Object] Status of the local user
  #
  join: (status = {}) =>
    @joinCheckTimeout = setTimeout ( =>
      @emit 'join_error'
    ), @options.joinTimeout

    @options.ownStatus[key] = status[key] for key in status
    @options.ownStatus.user_agent ||= palava.browser.getUserAgent()

    @distributor.send
      event: 'join_room'
      room_id: @id
      status: @options.ownStatus

  # Send leave room event to server
  #
  leave: =>
    if @channel
      @distributor.send
        event: 'leave_room'
    @emit 'left'

  # Makes sure room is closed by disconnecting all peer connections and clearing all timeouts
  #
  destroy: =>
    @getRemotePeers().forEach (peer) =>
      peer.closePeerConnection()
    clearTimeout(@joinCheckTimeout)

  # Find peer with the given id
  #
  # @param id [String] id of the searched peer
  #
  # @return [palava.Peer] The peer with the given id or `undefined`
  #
  getPeerById: (id) => @peers[id]

  # Get local peer
  #
  # @return [palava.Peer] The local peer
  #
  getLocalPeer:     => @localPeer

  # Get remote peers
  #
  # @return [Array] All peers except the local peer
  #
  getRemotePeers:   => @getAllPeers(false)

  # Get all peers
  #
  # @return [Array] All peers including the local peer
  #
  getAllPeers: (allowLocal = true) =>
    peers = []
    for id, peer of @peers
      if allowLocal || !peer.local
        peers.push peer
    peers
