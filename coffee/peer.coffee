#= require ./browser

palava = @palava

# Class representing a participant in a room
#
class palava.Peer extends @EventEmitter

  # @param id [String] ID of the participant
  # @param status [Object] An object conataining state which is exchanged through the palava machine
  # @option staus name [String] The chosen name of the participant
  #
  constructor: (id, status) ->
    @id     = id
    @status = status || {}
    @status.user_agent ||= palava.browser.getUserAgent()
    @joinTime = (new Date()).getTime()

  # Checks whether the participant is sending audio
  #
  # @return [Boolean] `true` if participant is sending audio
  #
  hasAudio: => palava.browser.checkForPartialSupport() || @getStream() && @getStream().getAudioTracks().length # TODO is the || really correct? Should this be the same for local and remote?

  # Checks whether the participant is muted
  #
  # @return [Boolean] `true` if participant is muted
  #
  isMuted:  => if @muted  then true else false

  # TODO: what is ready?

  # Checks whether the peer is ready
  #
  # @return [Boolean] `true` if participant is ready
  #
  isReady:  => if @ready  then true else false

  # Checks whether the participant is local
  #
  # @return [Boolean] `true` if participant is the local peer
  #
  isLocal:  => if @local  then true else false
