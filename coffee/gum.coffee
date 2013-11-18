#= require ./browser

class Gum extends EventEmitter
  constructor: (config) ->
    @config = config || { video: true, audio: true }
    @stream = null

  requestStream: =>
    palava.browser.getUserMedia.call(
      navigator
      , @config
      , (stream) => # success
        @stream = stream
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

namespace 'palava', (exports) ->
  exports.Gum = Gum
