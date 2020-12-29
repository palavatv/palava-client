#= require ./browser
#= require ./peer

palava = @palava

# A specialized peer representing the local user in the conference
class palava.LocalPeer extends palava.Peer

  # @param id [String] Unique ID of the local peer in the conference
  # @param status [Object] An object conataining state which is exchanged through the palava machine (see `palava.Peer` for more informations)
  # @param room [palava.Room] The room in which the peer is present
  constructor: (id, status, room) ->
    @muted    = true # currently refers to displaying of local stream, not the sent one
    @local    = true
    super id, status

    @room = room
    @userMedia = room.userMedia

    @setupRoom()
    @setupUserMedia()

  # Initializes the events based on the userMedia
  #
  # @nodoc
  #
  setupUserMedia: =>
    @userMedia.on 'stream_released', =>
      @ready = false
      @emit 'stream_removed'
    @userMedia.on 'stream_ready', (e) =>
      @ready = true
      @emit 'stream_ready', e
    @userMedia.on 'stream_error', (e) =>
      @emit 'stream_error', e
    @userMedia.on 'display_stream_ready', (e) =>
      @emit 'display_stream_ready', e
    @userMedia.on 'display_stream_error', (e) =>
      @emit 'display_stream_error', e
    if @getStream()
      @ready = true
      @emit 'stream_ready'

  # Initializes the events based on the room
  #
  # @nodoc
  #
  setupRoom: =>
    @room.peers[@id] = @room.localPeer = @
    @on 'update',         => @room.emit('peer_update', @)
    @on 'stream_ready',   => @room.emit('peer_stream_ready', @)
    @on 'stream_removed', => @room.emit('peer_stream_removed', @)

  # Returns the local stream
  #
  # @return [MediaStream] The local stream as defined by the WebRTC API
  #
  getStream: =>
    @userMedia.getStream()

  requestDisplaySharing: =>
    @userMedia.requestDisplaySharing()

  # Updates the status of the local peer. The status is extended or updated with the given items.
  #
  # @param status [Object] Object containing the new items
  #
  updateStatus: (status) =>
    if !status || !(status instanceof Object) || Object.keys(status).length == 0 then return status
    @status[key] = status[key] for key of status
    @status.user_agent ||= palava.browser.getUserAgent()
    @room.channel.send # TODO clarify how to send stuff
      event: 'update_status'
      status: @status
    @status

  disableAudio: =>
    return unless @ready
    for track in @getStream().getAudioTracks()
      track.enabled = false

  enableAudio: =>
    return unless @ready
    for track in @getStream().getAudioTracks()
      track.enabled = true

  disableVideo: =>
    return unless @ready
    for track in @getStream().getVideoTracks()
      track.enabled = false

  enableVideo: =>
    return unless @ready
    for track in @getStream().getVideoTracks()
      track.enabled = true

  # Leave the room
  leave: =>
    @ready = false
    # @emit 'stream_removed'
    # TODO: nobody listens on this?
    @emit 'left'
