#= require ./local_peer
#= require ./remote_peer
#= require ./gum
#= require ./distributor

class palava.Room extends EventEmitter
  constructor: (roomId, channel, userMedia, options = {}) ->
    @id        = roomId
    @userMedia = userMedia
    @channel   = channel
    @peers   = {}
    @options   = options

    @setupUserMedia()
    @setupChannel()
    @setupDistributor()
    @setupOptions()

  setupUserMedia: =>
    @userMedia.on 'stream_ready', (event) => @emit 'local_stream_ready', event.stream
    @userMedia.on 'stream_released',      => @emit 'local_stream_removed'

  setupChannel: => # TODO move to session?
    @channel.on 'not_reachable', (e) => @emit 'signaling_not_reachable', e
    @channel.on 'error',         (e) => @emit 'signaling_error', e
    @channel.on 'close',         (e) => @emit 'signaling_close', e

  setupOptions: =>
    @options.joinTimeout ||= 1000
    @options.ownStatus ||= {}

  setupDistributor: =>
    @distributor = palava.Distributor(@channel)

    @distributor.on 'joined_room', (msg) =>
      clearTimeout(@joinCheckTimeout)
      new palava.LocalPeer(msg.own_id, @options.ownStatus, @)
      for peer in msg.peers
        newPeer = new palava.RemotePeer(peer.peer_id, peer.status, @)
        newPeer.sendOfferIf !palava.browser.isChrome()
      @emit "joined", @

    @distributor.on 'new_peer', (msg) =>
      newPeer = new palava.RemotePeer(msg.peer_id, msg.status, @)
      newPeer.sendOfferIf msg.status.user_agent == 'chrome'
      @emit 'peer_joined', newPeer

    @distributor.on 'error',    (msg) => @emit 'signaling_error',    msg.message

    @distributor.on 'shutdown', (msg) => @emit 'signaling_shutdown', msg.seconds

  join: (status = {}) =>
    @joinCheckTimeout = setTimeout ( =>
      @emit 'join_error', 'Not able to join room'
      @leave() # TODO ?
    ), @options.joinTimeout

    @options.ownStatus[key] = status[key] for key in status
    @options.ownStatus.user_agent ||= palava.browser.getUserAgent()

    @distributor.send
      event: 'join_room'
      room_id: @id
      status: @options.ownStatus

  leave: =>
    @emit 'leave'
    @channel && @channel.close()
    @localPeer && @localPeer.stream && @localPeer.stream.close()

  getPeerById: (id) => @peers[id]
  getLocalPeer:     => @localPeer
  getRemotePeers:   => @getAllPeers(false)
  getAllPeers: (allowLocal = true) =>
    peers = []
    for id, peer of @peers
      if allowLocal || !peer.local
        peers.push peer
    peers
