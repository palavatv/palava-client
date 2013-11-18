#= require ./browser
#= require ./peer
#= require ./distributor

# TODO pack 'peer left' into 'send_to_peer' on server side
class RemotePeer extends palava.Peer
  constructor: (id, status, room) ->
    @muted = false
    @local = false
    super id, status

    @room = room
    @remoteStream = null

    @setupRoom()
    @setupPeerConnection()
    @setupDistributor()

  getStream: =>
    @remoteStream

  hasAudio: =>
    @remoteStream && ( palava.browser.checkForPartialSupport() || @remoteStream.getAudioTracks().length ) # TODO is the || really correct?

  toggleMute: =>
    @muted = !@muted

  setupPeerConnection: =>
    @peerConnection = new palava.browser.PeerConnection({iceServers: [{url: @room.options.stun}]}, palava.browser.getPeerConnectionOptions())

    @peerConnection.onicecandidate = (event) =>
      if event.candidate
        @distributor.send
          event: 'ice_candidate'
          sdpmlineindex: event.candidate.sdpMLineIndex
          sdpmid: event.candidate.sdpMid
          candidate: event.candidate.candidate

    @peerConnection.onaddstream = (event) =>
      @remoteStream = event.stream
      @ready = true
      @emit 'stream_ready'

    @peerConnection.onremovestream = (event) =>
      @remoteStream = null
      @ready = false
      @emit 'stream_removed'

    # TODO onsignalingstatechange

    if @room.localPeer.getStream()
      @peerConnection.addStream @room.localPeer.getStream()
    else
      # not suppored yet

    @peerConnection

  setupDistributor: =>
    # TODO _ in events also in rtc-server
    # TODO consistent protocol naming
    @distributor = palava.Distributor(@room.channel, @id)

    @distributor.on 'peer_left', (msg) =>
      if @ready
        @remoteStream = null
        @emit 'stream_removed'
        @ready = false
      @peerConnection.close()
      @emit 'left'

    @distributor.on 'ice_candidate', (msg) =>
      candidate = new palava.browser.IceCandidate({candidate: msg.candidate, sdpMLineIndex: msg.sdpmlineindex, sdpMid: msg.sdpmid})
      @peerConnection.addIceCandidate(candidate)

    @distributor.on 'offer', (msg) =>
      @peerConnection.setRemoteDescription(new palava.browser.SessionDescription(msg.sdp))
      @emit 'offer' # ignored so far
      @sendAnswer()

    @distributor.on 'answer', (msg) =>
      @peerConnection.setRemoteDescription(new palava.browser.SessionDescription(msg.sdp))
      @emit 'answer' # ignored so far

    @distributor.on 'peer_updated_status', (msg) =>
      @status = msg.status
      @emit 'update'
    @distributor

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
    @on 'oaerror',    (e) => @room.emit('peer_oaerror', @, e)

  sendOffer: =>
    @peerConnection.createOffer  @sdpSender('offer'),  @oaError, palava.browser.getConstraints()
    @mozillaCheckAddStream()

  sendOfferIf: (cond) =>
    if cond then @sendOffer()

  sendAnswer: =>
    @peerConnection.createAnswer @sdpSender('answer'), @oaError, palava.browser.getConstraints()
    @mozillaCheckAddStream()

  sdpSender: (event) =>
    (sdp) =>
      sdp = palava.browser.patchSDP(sdp)
      @peerConnection.setLocalDescription(sdp)
      @distributor.send
        event: event
        sdp: sdp

  oaError: (error) =>
    @emit 'oaerror', error

  mozillaCheckAddStream: =>
    if palava.browser.isMozilla() # TODO research remove / bug ticket
      timeouts = $([100, 200, 400, 1000, 2000, 4000, 8000, 12000, 16000]).map (_, n) =>
        setTimeout ( =>
          if remoteTrack = ( @peerConnection.remoteStreams && @peerConnection.remoteStreams[0] ) ||
                           ( @peerConnection.getRemoteStreams() && @peerConnection.getRemoteStreams()[0] )
            timeouts.each (_, t) => clearTimeout(t)
            @peerConnection.onaddstream({stream: remoteTrack})
        ), n

namespace 'palava', (exports) -> exports.RemotePeer = RemotePeer
