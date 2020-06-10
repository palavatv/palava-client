#= require ./browser

palava = @palava

class palava.Gum extends @EventEmitter
  constructor: (config) ->
    @config = config || { video: true, audio: true }
    @stream = null # this stream switches from localStream to displayStream on request
    @localStream = null
    @displayStream = null

  changeConfig: (config) =>
    @config = config
    @releaseStream()
    @requestStream()

  requestStream: =>
    navigator.mediaDevices.getUserMedia(
      @config
    ).then(
      (stream) =>
        @localStream = stream.clone()
        @stream = stream
        @emit 'stream_ready', stream
    ).catch(
      (error) =>
        @emit 'stream_error', error
    )

  requestDisplaySharing: =>
    navigator.mediaDevices.getDisplayMedia(
      {video:true}
    ).then(
      (stream) =>
        # add audio track to the display stream (if any)
        if @localStream.getAudioTracks().length > 0
          stream.addTrack(@localStream.getAudioTracks()[0], @localStream)
        @displayStream = stream.clone()
        @stream = stream
        @emit 'display_stream_ready', stream
    ).catch(
      (error) =>
        @emit 'display_stream_error', error
    )

  stopDisplaySharing: =>
    @stream = @localStream
    @emit 'display_stream_stop', @displayStream
    @displayStream = null

  getStream: =>
    @stream

  getLocalStream: =>
    @localStream

  getDisplayStream: =>
    @displayStream

  releaseStream: =>
    if @stream
      @stream.getAudioTracks().forEach( (track) => track.stop() )
      @stream.getVideoTracks().forEach( (track) => track.stop() )
      @stream = null
      @emit 'stream_released', @
      true
    else
      false
