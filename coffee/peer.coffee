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
    @ready  = false
    @error  = null

  # Checks whether the participant is sending audio
  #
  # @return [Boolean] `true` if participant is sending audio
  #
  transmitsAudio: () =>
    return @getStream()?.getAudioTracks()?[0]?.enabled

  # Checks whether the participant is could send audio (but maybe has it muted)
  #
  # @return [Boolean] `true` if participant has audio tracks
  #
  hasAudio: () =>
    return !!@getStream()?.getAudioTracks()?[0]

  # Checks whether the participant is sending audio
  #
  # @return [Boolean] `true` if participant is sending audio
  #
  transmitsVideo: =>
    return @getStream()?.getVideoTracks()?[0]?.enabled

  # Checks whether the participant is could send video (but maybe put in on hold)
  #
  # @return [Boolean] `true` if participant has audio tracks
  #
  hasVideo: () =>
    return !!@getStream()?.getVideoTracks()?[0]

  # Checks whether the peer connection is somewhat erroneous
  #
  # @return [Boolean] `true` if participant connection has an error
  #
  hasError: => if @error  then true else false

  # Returns the error message of the peer
  #
  # @return [String] error message
  #
  getError: => @error

  # Checks whether the participant is muted
  #
  # @return [Boolean] `true` if participant is muted
  #
  isMuted:  => if @muted  then true else false

  # Checks whether the peer is ready
  #
  # @return [Boolean] `true` if participant is ready, that they have a stream
  #
  isReady:  => if @ready  then true else false

  # Checks whether the participant is local
  #
  # @return [Boolean] `true` if participant is the local peer
  #
  isLocal:  => if @local  then true else false

  # Checks whether the participant is remote
  #
  # @return [Boolean] `true` if participant is the remote peer
  #
  isRemote:  => if @local  then false else true