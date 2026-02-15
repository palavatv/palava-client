import adapter from 'webrtc-adapter'

# Checks whether the browser is a Firefox
#
# @return [Boolean] `true` if Firefox
#
export isMozilla = ->
  adapter.browserDetails.browser == 'firefox'

# Checks whether the browser is a Chrome/Chromium
#
# @return [Boolean] `true` if Chrome
#
export isChrome = ->
  adapter.browserDetails.browser == 'chrome'

# Checks which browser is used
#
# @return [String] A well defined id of the browser (firefox, chrome, safari, or unknown)
#
export getUserAgent = ->
  adapter.browserDetails.browser

# Checks which browser is used
#
# @return [Integer] The user agent version
#
export getUserAgentVersion = ->
  adapter.browserDetails.version

# Checks whether the WebRTC support of the browser should be compatible with palava
#
# Please note: The test requires network connectivity
#
# @return [Boolean] `true` if the browser is supported by palava
#
export checkForWebrtcError = ->
  try
    new window.RTCPeerConnection({ iceServers: [] })
  catch e
    return e

  !(window.RTCPeerConnection && window.RTCIceCandidate && window.RTCSessionDescription && navigator.mediaDevices && navigator.mediaDevices.getUserMedia)

# Get WebRTC constraints argument
#
# @return [Object] Appropriate constraints for WebRTC
#
export getConstraints = ->
  optional: []
  mandatory:
    OfferToReceiveAudio: true
    OfferToReceiveVideo: true

# Get WebRTC PeerConnection options
#
# @return [Object] Appropriate options for the PeerConnection
#
export getPeerConnectionOptions = ->
  if isChrome()
    { optional: [{ DtlsSrtpKeyAgreement: true }] }
  else
    {}

# Attaches a media stream to a DOM element
#
# @param element [DOM Element] The element to attach the stream to
# @param stream [MediaStream] The stream to attach
#
export attachMediaStream = (element, stream) ->
  if stream
    element.srcObject = stream
  else
    element.pause()
    element.srcObject = null

# Attaches a peer's stream to a DOM element
#
# @param element [DOM Element] The element to attach the stream to
# @param peer [Peer] The peer whose stream to attach
#
export attachPeer = (element, peer) ->
  attach = ->
    attachMediaStream(element, peer.getStream())

    if peer.isLocal()
      element.setAttribute('muted', true)

    element.play()

  if peer.getStream()
    attach()
  else
    peer.on 'stream_ready', () ->
      attach()
