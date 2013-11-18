#= require ./browser

class Peer extends EventEmitter
  constructor: (id, status) ->
    @id     = id
    @status = status || {}
    @status.user_agent ||= palava.browser.getUserAgent()
    @joinTime = (new Date()).getTime()

  hasAudio: => palava.browser.checkForPartialSupport() || @getStream() && @getStream().getAudioTracks().length # TODO is the || really correct? Should this be the same for local and remote?
  isMuted:  => if @muted  then true else false
  isReady:  => if @ready  then true else false
  isLocal:  => if @local  then true else false

namespace 'palava', (exports) -> exports.Peer = Peer
