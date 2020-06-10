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
  # @param offers [Boolean] If true, we send the offer, otherwise the peer
  # @param turnCredentials [Object] username and password for the turn server (optional)
  #
  constructor: (id, status, room, offers, turnCredentials) ->
    @muted = false
    @local = false
    super id, status

    @room = room
    @remoteStream = null
    @turnCredentials = turnCredentials

    @dataChannels = {}

    @offers = offers
    @makingOffer = false
    @ignoreOffer = false
    @setRemoteAnswerPending = false

    @setupRoom()
    @setupDistributor()
    @setupPeerConnection(offers)
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
    if @room.options.turnUrls && @turnCredentials
      options.push
        urls: @room.options.turnUrls
        username: @turnCredentials.user
        credential: @turnCredentials.password
    {iceServers: options}

  # Sets up the peer connection and its events   #
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

    @peerConnection.onnegotiationneeded = () =>
      @sendOffer()

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

    if @room.localPeer.getStream()
      for track in @room.localPeer.getStream().getTracks()
        @peerConnection.addTrack(track, @room.localPeer.getStream())

    @room.localPeer.on 'display_stream_ready', (stream) =>
      videoSender = @peerConnection.getSenders().find(
        (sender) => sender.track.kind == "video"
      )
      if videoSender
        # if there is a local video track then replace it because that's faster
        # and does not need renegotiation
        videoSender.replaceTrack(track)
      else
        @peerConnection.addTrack(stream.getVideoTracks()[0],
                                 @room.localPeer.getStream())

    @room.localPeer.on 'display_stream_stop', (stream) =>
      localVideoTracks = @room.localPeer.getLocalStream().getVideoTracks()
      if localVideoTracks.length > 0
        # if there was a local video track then reuse the display video track
        # because it's faster and does not need renegotiation
        videoSender = @peerConnection.getSenders().find(
          (sender) => sender.track.kind == "video"
        )
        videoSender.replaceTrack(localVideoTracks[0])
      else
        @peerConnection.removeTrack(stream.getVideoTracks()[0])

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

  # Sets up the distributor connecting to the participant
  #
  # @nodoc
  #
  setupDistributor: =>
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
      unless @room.options.filterIceCandidateTypes.includes(candidate.type)
        await @peerConnection.addIceCandidate(candidate)

    @distributor.on 'offer', (msg) =>
      # we sent an offer already and are the preferred offerer, so we don't back down
      return if @pendingOffer && @offers

      # we backed down, so we drop the pending offer and choose the other peer's offer
      @pendingOffer = null

      await @peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp))
      @sendAnswer()

    @distributor.on 'answer', (msg) =>
      await @peerConnection.setLocalDescription(@pendingOffer) if @pendingOffer
      @pendingOffer = null
      await @peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp))

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

  sendMessage: (data) =>
    @distributor.send
      event: 'message'
      data: data

  # Sends the offer to create a peer connection
  #
  sendOffer: =>
    @peerConnection.createOffer  @sdpSender('offer'),  @oaError, palava.browser.getConstraints() if @peerConnection.signalingState == "stable" && !@pendingOffer

  # Sends the answer to create a peer connection
  #
  sendAnswer: =>
    @peerConnection.createAnswer @sdpSender('answer'), @oaError, palava.browser.getConstraints()


  # Send offer/answer
  #
  # @nodoc
  #
  sdpSender: (event) =>
    (sdp) =>
      if event == 'offer'
        @pendingOffer = sdp
      else
        await @peerConnection.setLocalDescription(sdp)
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
