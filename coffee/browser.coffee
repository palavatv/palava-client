palava = @palava
$ = @$

# Checks whether the browser is a Firefox
#
# @return [Boolean] `true` if Firefox
#
palava.browser.isMozilla = ->
  if window.mozRTCPeerConnection then true
  else false

# Checks whether the browser is a Chrome/Chromium
#
# @return [Boolean] `true` if Chrome
#
palava.browser.isChrome = ->
  /Chrome/i.test(navigator.userAgent)

# Checks which browser is used
#
# @return [String] A well defined id of the browser (firefox, chrome or unknown)
#
palava.browser.getUserAgent = ->
  if palava.browser.isMozilla()
    'firefox'
  else if palava.browser.isChrome()
    'chrome'
  else
    'unknown'

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
# @param element [JQuery Elements] Element to put into fullscreen
# @param eventName [String] Event name on which to activate fullscreen
#
palava.browser.registerFullscreen = (element, eventName) ->
  # TODO: provide only function to activate fullscreen to reduce complexity and widen use cases of helper?
  if(element[0].requestFullscreen)
    element.on eventName, -> this.requestFullscreen()
  else if(element[0].mozRequestFullScreen)
    element.on eventName, -> this.mozRequestFullScreen()
  else if(element[0].webkitRequestFullscreen)
    element.on eventName, -> this.webkitRequestFullscreen()

palava.browser.attachMediaStream = (element, stream) ->
  if stream
    $(element).prop 'srcObject',  stream
  else
    $(element).each (key, el) -> el.pause()
    $(element).prop 'srcObject', null

palava.browser.attachPeer = (element, peer) ->
  attach = () ->
    palava.browser.attachMediaStream(element, peer.getStream())

    if peer.isLocal()
      element.attr('muted', true)

    element[0].play()

  if peer.getStream()
    attach()
  else
    peer.on 'stream_ready', () ->
      attach()
