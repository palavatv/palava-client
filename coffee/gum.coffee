#= require ./browser

palava = @palava

class palava.Gum extends @EventEmitter
  constructor: (config) ->
    @config = config || { video: true, audio: true }
    @stream = null

  changeConfig: (config) =>
    @config = config
    @releaseStream()
    @requestStream()

  requestStream: =>
    navigator.mediaDevices.getUserMedia(
      @config
    ).then(
      (stream) =>
        @stream = stream
        @emit 'stream_ready', stream
    ).catch(
      (error) =>
        @emit 'stream_error', error
    )

  getStream: =>
    @stream

  releaseStream: =>
    if @stream
      @stream.getAudioTracks().forEach( (track) => track.stop() )
      @stream.getVideoTracks().forEach( (track) => track.stop() )
      @stream = null
      @emit 'stream_released', @
      true
    else
      false
