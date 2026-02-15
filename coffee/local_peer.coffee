import * as browser from './browser.js'
import { Peer } from './peer.js'

# A specialized peer representing the local user in the conference
export class LocalPeer extends Peer

  # @param id [String] Unique ID of the local peer in the conference
  # @param status [Object] An object containing state which is exchanged through the palava machine (see `palava.Peer` for more informations)
  # @param room [palava.Room] The room in which the peer is present
  constructor: (id, status, room) ->
    super id, status
    @muted = true
    @local = true

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

  # Updates the status of the local peer. The status is extended or updated with the given items.
  #
  # @param status [Object] Object containing the new items
  #
  updateStatus: (status) =>
    if !status || !(status instanceof Object) || Object.keys(status).length == 0 then return status
    @status[key] = status[key] for key of status
    @status.user_agent ||= browser.getUserAgent()
    @room.channel.send
      event: 'update_status'
      status: @status
    @status

  # Remove video track and emit event for renegotiation
  #
  disableVideo: =>
    stream = @getStream()
    return unless stream
    for track in stream.getVideoTracks()
      track.stop()
      stream.removeTrack(track)
      @emit 'video_removed', track, stream

  # Remove audio track and emit event for renegotiation
  #
  disableAudio: =>
    stream = @getStream()
    return unless stream
    for track in stream.getAudioTracks()
      track.stop()
      stream.removeTrack(track)
      @emit 'audio_removed', track, stream

  # Request video from getUserMedia and add it to the local stream
  # Emits 'video_added' event which remote peers listen to for adding the track to their connections
  #
  # @param constraints [Object] Video constraints for getUserMedia (optional, defaults to true)
  # @return [Promise] Resolves with the video track when added, rejects on error
  #
  requestVideo: (constraints = true) =>
    return Promise.reject(new Error('No stream available')) unless @getStream()
    return Promise.resolve(@getStream().getVideoTracks()[0]) if @hasVideo()

    navigator.mediaDevices.getUserMedia({ video: constraints, audio: false })
      .then (stream) =>
        videoTrack = stream.getVideoTracks()[0]
        return Promise.reject(new Error('No video track received')) unless videoTrack

        # Add track to our local stream
        @getStream().addTrack(videoTrack)

        # Emit event - remote peers will listen and add the track to their connections
        @emit 'video_added', videoTrack, @getStream()
        videoTrack
      .catch (error) =>
        @emit 'video_error', error
        Promise.reject(error)

  # Request audio from getUserMedia and add it to the local stream
  # Emits 'audio_added' event which remote peers listen to for adding the track to their connections
  #
  # @param constraints [Object] Audio constraints for getUserMedia (optional, defaults to true)
  # @return [Promise] Resolves with the audio track when added, rejects on error
  #
  requestAudio: (constraints = true) =>
    return Promise.reject(new Error('No stream available')) unless @getStream()
    return Promise.resolve(@getStream().getAudioTracks()[0]) if @hasAudio()

    navigator.mediaDevices.getUserMedia({ video: false, audio: constraints })
      .then (stream) =>
        audioTrack = stream.getAudioTracks()[0]
        return Promise.reject(new Error('No audio track received')) unless audioTrack

        # Add track to our local stream
        @getStream().addTrack(audioTrack)

        # Emit event - remote peers will listen and add the track to their connections
        @emit 'audio_added', audioTrack, @getStream()
        audioTrack
      .catch (error) =>
        @emit 'audio_error', error
        Promise.reject(error)

  # Leave the room
  leave: =>
    @ready = false
    @emit 'left'
