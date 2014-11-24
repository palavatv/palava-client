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

  detectMedia: =>
    @config = {video: false, audio: false}
    @config.video = true if @stream && @stream.getVideoTracks().length > 0
    @config.audio = true if @stream && @stream.getAudioTracks().length > 0

  requestStream: =>
    palava.browser.getUserMedia.call(
      navigator
      , @config
      , (stream) => # success
        @stream = stream
        @detectMedia()
        @emit 'stream_ready', @
      , => # error
        @emit 'stream_error', @
    )
    true

  getStream: =>
    @stream

  releaseStream: =>
    if @stream
      @stream.stop()
      @stream = null
      @emit 'stream_released', @
      true
    else
      false
