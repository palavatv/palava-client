#= require ./browser
#= require ./peer

class LocalPeer extends palava.Peer
  constructor: (id, status, room) ->
    @muted    = true # currently refers to displaying of local stream, not the sent one
    @local    = true
    super id, status

    @room = room
    @userMedia = room.userMedia

    @setupRoom()
    @setupUserMedia()

  setupUserMedia: =>
    @userMedia.on 'stream_released', =>
      @ready = false
      @emit 'stream_removed'
    @userMedia.on 'stream_ready', (e) =>
      @ready = true
      @emit 'stream_ready', e
    if @getStream()
      @ready = true
      @emit 'stream_ready'

  setupRoom: =>
    @room.peers[@id] = @room.localPeer = @
    @on 'update',         => @room.emit('peer_update', @)
    @on 'stream_ready',   => @room.emit('peer_stream_ready', @)
    @on 'stream_removed', => @room.emit('peer_stream_removed', @)

  getStream: =>
    @userMedia.getStream()

  updateStatus: (status) =>
    if !status || !(status instanceof Object) || Object.keys(status).length == 0 then return status
    @status[key] = status[key] for key of status
    @status.user_agent ||= palava.browser.getUserAgent()
    @room.channel.send # TODO clarify how to send stuff
      event: 'update_status'
      status: @status
    @status

  hasAudio: =>
    false

  toggleMute: =>
    false

  leave: =>
    @ready = false
    # @emit 'stream_removed'
    @emit 'left'

namespace 'palava', (exports) -> exports.LocalPeer = LocalPeer
