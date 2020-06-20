#= require ./browser
#= require ./peer
#= require ./distributor
#= require ./data_channel

palava = @palava

# TODO pack 'peer left' into 'send_to_peer' on server side

# A remote participant in a room
#
class palava.RemotePeer extends palava.Peer

  # @param id [String] ID of the participant
  # @param status [Object] Status object of the participant
  # @param room [palava.Room] Room the participant is in
  #
  constructor: (id, status, room, offers) ->
    @muted = false
    @local = false
    super id, status

    @room = room
    @remoteStream = null

    @dataChannels = {}

    @setupRoom()
    @setupPeerConnection(offers)
    @setupDistributor()

    @offers = offers
    if offers
      @sendOffer()

  # Get the stream
  #
  # @return [MediaStream] Remote stream as defined by WebRTC
  #
  getStream: =>
    @remoteStream

  # Toggle the mute state of the peer
  #
  toggleMute: =>
    @muted = !@muted

  # Generates the STUN and TURN options for a peer connection
  #
  # @return [Object] ICE options for the peer connections
  #
  generateIceOptions: =>
    options = []
    if @room.options.stun
      options.push({urls: [@room.options.stun]})
    if @room.options.turn && @turnCredentials
      options.push
        urls: [@room.options.turn]
        username: @turnCredentials.user
        credential: @turnCredentials.password
    {iceServers: options}

  # Sets up the peer connection and its events
  #
  # @nodoc
  #
  setupPeerConnection: (offers) =>
    @peerConnection = new RTCPeerConnection(@generateIceOptions(), palava.browser.getPeerConnectionOptions())

    @peerConnection.onicecandidate = (event) =>
      if event.candidate
        @distributor.send
          event: 'ice_candidate'
          sdpmlineindex: event.candidate.sdpMLineIndex
          sdpmid: event.candidate.sdpMid
          candidate: event.candidate.candidate

    @peerConnection.ontrack = (event) =>
      @remoteStream = event.streams[0]
      @ready = true
      @emit 'stream_ready'

    @peerConnection.onremovestream = (event) =>
      @remoteStream = null
      @ready = false
      @emit 'stream_removed'

    @peerConnection.oniceconnectionstatechange = (event) =>
      connectionState = event.target.iceConnectionState

      switch connectionState
        when 'connecting'
          @error = null
          @emit 'connection_pending'
        when 'connected'
          @error = null
          @emit 'connection_established'
        when 'failed'
          @error = "connection_failed"
          @emit 'connection_failed'
        when 'disconnected'
          @error = "connection_disconnected"
          @emit 'connection_disconnected'
        when 'closed'
          @error = "connection_closed"
          @emit 'connection_closed'

    # TODO onsignalingstatechange

    if @room.localPeer.getStream()
      @peerConnection.addStream @room.localPeer.getStream()
    else
      # not suppored yet

    # data channel setup

    if @room.options.dataChannels?
      registerChannel = (channel) =>
        name = channel.label
        wrapper = new palava.DataChannel(channel)
        @dataChannels[name] = wrapper
        @emit 'channel_ready', name, wrapper

      if offers
        for label, options of @room.options.dataChannels
          channel = @peerConnection.createDataChannel(label, options)

          channel.onopen = () ->
            registerChannel(@)
      else
        @peerConnection.ondatachannel = (event) =>
          registerChannel(event.channel)

    @peerConnection

  # Check if turn was already tried as (last) connection option
  #
  # @return [Boolean] true if turn was tried by using the tryTurn function
  #
  hasTriedTurn: => !!@turnCredentials

  # Check if turn was already tried as (last) connection option
  #
  # @return [Object] true if turn was tried by using the tryTurn function
  #
  tryTurn: (credentials) =>
    @closePeerConnection()
    @turnCredentials = credentials
    @setupPeerConnection(@offers)

  # Sets up the distributor connecting to the participant
  #
  # @nodoc
  #
  setupDistributor: =>
    # TODO _ in events also in rtc-server
    # TODO consistent protocol naming
    @distributor = new palava.Distributor(@room.channel, @id)

    @distributor.on 'peer_left', (msg) =>
      if @ready
        @remoteStream = null
        @emit 'stream_removed'
        @ready = false
      @peerConnection.close()
      @emit 'left'

    @distributor.on 'ice_candidate', (msg) =>
      # empty msg.candidate causes error messages in firefox, so let RTCPeerConnection deal with it and return here
      return if msg.candidate == ""
      candidate = new RTCIceCandidate({candidate: msg.candidate, sdpMLineIndex: msg.sdpmlineindex, sdpMid: msg.sdpmid})
      @peerConnection.addIceCandidate(candidate)

    @distributor.on 'offer', (msg) =>
      @peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp))
      @emit 'offer' # ignored so far
      @sendAnswer()

    @distributor.on 'answer', (msg) =>
      @peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp))
      @emit 'answer' # ignored so far

    @distributor.on 'peer_updated_status', (msg) =>
      @status = msg.status
      @emit 'update'

    @distributor.on 'message', (msg) =>
      @emit 'message', msg.data

    @distributor

  # Forward events to the room
  #
  # @nodoc
  #
  setupRoom: =>
    @room.peers[@id] = @
    @on 'left', =>
      delete @room.peers[@id]
      @room.emit 'peer_left', @
    @on 'offer',          => @room.emit('peer_offer', @)
    @on 'answer',         => @room.emit('peer_answer', @)
    @on 'update',         => @room.emit('peer_update', @)
    @on 'stream_ready',   => @room.emit('peer_stream_ready', @)
    @on 'stream_removed', => @room.emit('peer_stream_removed', @)
    @on 'connection_pending',      => @room.emit('peer_connection_pending', @)
    @on 'connection_established',  => @room.emit('peer_connection_established', @)
    @on 'connection_failed',       => @room.emit('peer_connection_failed', @)
    @on 'connection_disconnected', => @room.emit('peer_connection_disconnected', @)
    @on 'connection_closed',       => @room.emit('peer_connection_closed', @)
    @on 'oaerror',    (e) => @room.emit('peer_oaerror', @, e)
    @on 'channel_ready', (n, c) => @room.emit('peer_channel_ready', @, n, c)

  # Sends the offer for a peer connection
  #
  # @nodoc
  #
  sendOffer: =>
    @peerConnection.createOffer  @sdpSender('offer'),  @oaError, palava.browser.getConstraints()

  # Sends the answer to create a peer connection
  #
  sendAnswer: =>
    @peerConnection.createAnswer @sdpSender('answer'), @oaError, palava.browser.getConstraints()

  sendMessage: (data) =>
    @distributor.send
      event: 'message'
      data: data

  # Helper for sending sdp
  #
  # @nodoc
  #
  sdpSender: (event) =>
    (sdp) =>
      @peerConnection.setLocalDescription(sdp)
      @distributor.send
        event: event
        sdp: sdp

  # TODO: what is this?
  #
  # @nodoc
  #
  oaError: (error) =>
    @emit 'oaerror', error

  # End peer connection
  #
  closePeerConnection: =>
    @peerConnection?.close()
    @peerConnection = null
