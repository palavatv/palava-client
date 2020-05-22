palava = @palava
adapter = @adapter

# Checks whether the browser is a Firefox
#
# @return [Boolean] `true` if Firefox
#
palava.browser.isMozilla = ->
  adapter.browserDetails.browser == 'firefox'

# Checks whether the browser is a Chrome/Chromium
#
# @return [Boolean] `true` if Chrome
#
palava.browser.isChrome = ->
  adapter.browserDetails.browser == 'chrome'

# Checks which browser is used
#
# @return [String] A well defined id of the browser (firefox, chrome, safari, or unknown)
#
palava.browser.getUserAgent = ->
  adapter.browserDetails.browser

# Checks which browser is used
#
# @return [Integer] The user agent version
#
palava.browser.getUserAgentVersion = ->
  adapter.browserDetails.version

# Checks whether the WebRTC support of the browser should be compatible with palava
#
# @return [Boolean] `true` if the browser is supported by palava
#
palava.browser.checkForWebrtcError = ->
  try
    new window.RTCPeerConnection({iceServers: []})
  catch e
    return e

  !( window.RTCPeerConnection && window.RTCIceCandidate && window.RTCSessionDescription && navigator.mediaDevices && navigator.mediaDevices.getUserMedia)

# Get WebRTC constraints argument
#
# @return [Object] Appropriate constraints for WebRTC
#
palava.browser.getConstraints = () ->
  constraints =
    optional: []
    mandatory:
      OfferToReceiveAudio: true
      OfferToReceiveVideo: true
  constraints

# Get WebRTC PeerConnection options
#
# @return [Object] Appropriate options for the PeerConnection
#
palava.browser.getPeerConnectionOptions = () ->
  if palava.browser.isChrome()
    {"optional": [{"DtlsSrtpKeyAgreement": true}]}
  else
    {}

## DOM

# Activates fullscreen on the given event
#
# @param element [DOM Elements] Element to put into fullscreen
# @param eventName [String] Event name on which to activate fullscreen
#
palava.browser.registerFullscreen = (element, eventName) ->
  console.log("DEPRECATED: palava.browser.registerFullscreen will be removed from the palava library in early 2021")
  if(element.requestFullscreen)
    element.addEventListener eventName, -> this.requestFullscreen()
  else if(element.mozRequestFullScreen)
    element.addEventListener eventName, -> this.mozRequestFullScreen()
  else if(element.webkitRequestFullscreen)
    element.addEventListener eventName, -> this.webkitRequestFullscreen()

palava.browser.attachMediaStream = (element, stream) ->
  if stream
    element.srcObject = stream
  else
    element.pause()
    element.srcObject = null

palava.browser.attachPeer = (element, peer) ->
  attach = () ->
    palava.browser.attachMediaStream(element, peer.getStream())

    if peer.isLocal()
      element.setAttribute('muted', true)

    element.play()

  if peer.getStream()
    attach()
  else
    peer.on 'stream_ready', () ->
      attach()
