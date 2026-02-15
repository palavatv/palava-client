import * as browser from './browser.js'
import { Peer } from './peer.js'
import { Distributor } from './distributor.js'
import { DataChannel } from './data_channel.js'

# A remote participant in a room
#
export class RemotePeer extends Peer

  # @param id [String] ID of the participant
  # @param status [Object] Status object of the participant
  # @param room [Room] Room the participant is in
  # @param hasOfferPriority [Boolean] If true, we send the initial offer and win offer collisions (impolite)
  # @param turnCredentials [Object] username and password for the turn server (optional)
  #
  constructor: (id, status, room, hasOfferPriority, turnCredentials) ->
    super id, status
    @muted = false
    @local = false

    @room = room
    @remoteStream = null
    @turnCredentials = turnCredentials
    @hasOfferPriority = hasOfferPriority

    # Queue to ensure negotiation operations happen sequentially
    @negotiationQueue = Promise.resolve()

    @dataChannels = {}

    @setupRoom()
    @setupPeerConnection()
    @setupDistributor()

    if @hasOfferPriority
      @queueNegotiation(@createAndSendOffer)

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

  # Sets up the peer connection and its events
  #
  # @nodoc
  #
  setupPeerConnection: =>
    @peerConnection = new RTCPeerConnection(@generateIceOptions(), browser.getPeerConnectionOptions())

    @peerConnection.onicecandidate = (event) =>
      if event.candidate
        @distributor.send
          event: 'ice_candidate'
          sdpmlineindex: event.candidate.sdpMLineIndex
          sdpmid: event.candidate.sdpMid
          candidate: event.candidate.candidate

    @peerConnection.ontrack = (event) =>
      stream = event.streams[0]
      track = event.track

      # Set up stream if this is the first track
      if !@remoteStream
        @remoteStream = stream
        @ready = true
        @emit 'stream_ready'

        # Listen for tracks being added/removed from the remote stream
        @remoteStream.onaddtrack = (e) =>
          if e.track.kind == 'video'
            @emit 'video_added', e.track, @remoteStream
          else if e.track.kind == 'audio'
            @emit 'audio_added', e.track, @remoteStream
 
        @remoteStream.onremovetrack = (e) =>
          if e.track.kind == 'video'
            @emit 'video_removed', e.track, @remoteStream
          else if e.track.kind == 'audio'
            @emit 'audio_removed', e.track, @remoteStream
      else
        # Additional track added to existing stream
        if track.kind == 'video'
          @emit 'video_added', track, @remoteStream
        else if track.kind == 'audio'
          @emit 'audio_added', track, @remoteStream

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

    # Handle negotiationneeded event - queue an offer
    @peerConnection.onnegotiationneeded = =>
      @queueNegotiation(@createAndSendOffer)

    # Add local tracks if we have a stream
    localStream = @room.localPeer.getStream()
    if localStream
      for track in localStream.getTracks()
        @peerConnection.addTrack(track, localStream)

    # data channel setup
    if @room.options.dataChannels?
      registerChannel = (channel) =>
        name = channel.label
        wrapper = new DataChannel(channel)
        @dataChannels[name] = wrapper
        @emit 'channel_ready', name, wrapper

      if @hasOfferPriority
        for label, options of @room.options.dataChannels
          channel = @peerConnection.createDataChannel(label, options)

          channel.onopen = ->
            registerChannel(@)
      else
        @peerConnection.ondatachannel = (event) =>
          registerChannel(event.channel)

    @peerConnection

  # Queues a negotiation task to ensure sequential execution
  # Each task is a function that returns a Promise
  #
  # @param task [Function] Function returning a Promise
  #
  queueNegotiation: (task) =>
    @negotiationQueue = @negotiationQueue
      .then(task)
      .catch (error) =>
        @emit 'oaerror', error

  # Creates and sends an offer
  # This is queued via queueNegotiation to prevent race conditions
  #
  # @nodoc
  #
  createAndSendOffer: =>
    @peerConnection.createOffer(browser.getConstraints())
      .then (offer) =>
        @peerConnection.setLocalDescription(offer)
      .then =>
        @distributor.send
          event: 'offer'
          sdp: @peerConnection.localDescription
        @emit 'offer'

  # Handles an incoming offer
  # This is queued via queueNegotiation to prevent race conditions
  #
  # @param sdp [RTCSessionDescription] The remote offer
  # @nodoc
  #
  handleOffer: (sdp) =>
    # Check for offer collision: both peers sent offers at the same time
    # If we're impolite (hasOfferPriority) and we have a pending local offer, ignore incoming offer
    if @hasOfferPriority && @peerConnection.signalingState == 'have-local-offer'
      return Promise.resolve()

    # If we're polite and have a pending local offer, implicit rollback will happen
    # when we call setRemoteDescription with the incoming offer
    @peerConnection.setRemoteDescription(sdp)
      .then =>
        @peerConnection.createAnswer(browser.getConstraints())
      .then (answer) =>
        @peerConnection.setLocalDescription(answer)
      .then =>
        @distributor.send
          event: 'answer'
          sdp: @peerConnection.localDescription
        @emit 'answer'

  # Handles an incoming answer
  # This is queued via queueNegotiation to prevent race conditions
  #
  # @param sdp [RTCSessionDescription] The remote answer
  # @nodoc
  #
  handleAnswer: (sdp) =>
    # Only process answer if we're expecting one
    if @peerConnection.signalingState != 'have-local-offer'
      return Promise.resolve()

    @peerConnection.setRemoteDescription(sdp)

  # Adds a new track to this peer connection
  # Used when the local user enables video/audio after initially joining without it
  # Triggers renegotiation via onnegotiationneeded
  #
  # @param track [MediaStreamTrack] The track to add
  # @param stream [MediaStream] The stream the track belongs to
  #
  addTrack: (track, stream) =>
    return unless @peerConnection
    @peerConnection.addTrack(track, stream)

  # Removes a track from this peer connection
  # Used when the local user disables video/audio
  # Triggers renegotiation via onnegotiationneeded
  #
  # @param track [MediaStreamTrack] The track to remove
  #
  removeTrack: (track) =>
    return unless @peerConnection
    # Find the sender for this track and remove it
    sender = @peerConnection.getSenders().find (s) -> s.track == track
    if sender
      @peerConnection.removeTrack(sender)

  # Sets up the distributor connecting to the participant
  #
  # @nodoc
  #
  setupDistributor: =>
    @distributor = new Distributor(@room.channel, @id)

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
        @peerConnection.addIceCandidate(candidate)

    @distributor.on 'offer', (msg) =>
      sdp = new RTCSessionDescription(msg.sdp)
      @queueNegotiation => @handleOffer(sdp)

    @distributor.on 'answer', (msg) =>
      sdp = new RTCSessionDescription(msg.sdp)
      @queueNegotiation => @handleAnswer(sdp)

    @distributor.on 'peer_updated_status', (msg) =>
      @status = msg.status
      @emit 'update'

    @distributor.on 'message', (msg) =>
      @emit 'message', msg.data

    @distributor

  # Forward events to the room and listen for local peer events
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

    # Listen for local peer adding new tracks (when user enables video/audio after joining)
    @setupLocalPeerListeners()

  # Listen for video_added and audio_added events from the local peer
  # and add those tracks to this peer connection
  #
  # @nodoc
  #
  setupLocalPeerListeners: =>
    @localPeerVideoAddedHandler = (track, stream) =>
      @addTrack(track, stream)

    @localPeerAudioAddedHandler = (track, stream) =>
      @addTrack(track, stream)

    @localPeerVideoRemovedHandler = (track, stream) =>
      @removeTrack(track)
 
    @localPeerAudioRemovedHandler = (track, stream) =>
      @removeTrack(track)

    @room.localPeer.on 'video_added', @localPeerVideoAddedHandler
    @room.localPeer.on 'audio_added', @localPeerAudioAddedHandler
    @room.localPeer.on 'video_removed', @localPeerVideoRemovedHandler
    @room.localPeer.on 'audio_removed', @localPeerAudioRemovedHandler

    # Clean up listeners when this peer leaves
    @on 'left', =>
      @room.localPeer.off 'video_added', @localPeerVideoAddedHandler
      @room.localPeer.off 'audio_added', @localPeerAudioAddedHandler
      @room.localPeer.off 'video_removed', @localPeerVideoRemovedHandler
      @room.localPeer.off 'audio_removed', @localPeerAudioRemovedHandler

  sendMessage: (data) =>
    @distributor.send
      event: 'message'
      data: data

  # End peer connection
  #
  closePeerConnection: =>
    @peerConnection?.close()
    @peerConnection = null
