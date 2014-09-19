palava = @palava
$ = @$

palava.browser.PeerConnection     = window.PeerConnection || window.webkitPeerConnection00 || window.webkitRTCPeerConnection || window.mozRTCPeerConnection
palava.browser.IceCandidate       = window.mozRTCIceCandidate || window.RTCIceCandidate
palava.browser.SessionDescription = window.mozRTCSessionDescription || window.RTCSessionDescription
palava.browser.getUserMedia       = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia

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
    new palava.browser.PeerConnection({iceServers: []})
  catch e
    return e

  !( palava.browser.PeerConnection && palava.browser.IceCandidate && palava.browser.SessionDescription && palava.browser.getUserMedia)

# Check which version of Chrome is present
#
# @return [Integer] Chrome version number
#
palava.browser.chromeVersion = ->
  matches =  /Chrome\/(\d+)/i.exec(navigator.userAgent)
  if matches
    [_, version] = matches
    parseInt(version)
  else
    false

# Check whether the browser is only partially supported by palava
#
# @return [Boolean] `true` if there are no known bugs for the used browser
palava.browser.checkForPartialSupport = ->
  palava.browser.isChrome() && palava.browser.chromeVersion() < 26

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

# Patch given SDP
#
# @return [String] Adjusted SDP fixing bugs and compability issues
#
palava.browser.patchSDP = (sdp) ->
  return sdp if palava.browser.isChrome() && palava.browser.chromeVersion() >= 31
  chars = [33..58].concat([60..126]).map (a) ->
    String.fromCharCode(a)
  key = ''
  for i in [0...40]
    key += chars[Math.floor(Math.random() * chars.length)]
  crypto = 'a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:' + key + '\r\nc=IN'
  if sdp.sdp.indexOf('a=crypto') == -1
    sdp.sdp = sdp.sdp.replace(/c=IN/g, crypto)
  sdp

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

# TODO move this if out of the way here
if palava.browser.isMozilla()
  palava.browser.attachMediaStream = (element, stream) ->
    if stream
      $(element).prop 'mozSrcObject',  stream
    else
      $(element).each (key, el) -> el.pause()
      $(element).prop 'mozSrcObject', null

  # waiter = 0
  # palava.browser.cloneMediaStream = (to, from) ->
  #   # TODO: this is a very hacky way to avoid the connecting streams from colliding
  #   now = new Date().getTime()
  #   doIt = ->
  #     if $(from).prop("tagName") == 'VIDEO'
  #       $(to).prop 'mozSrcObject', from.mozSrcObject
  #       $(to).show()
  #       $(to)[0].play()
  #     else
  #       $(to).hide()
  #   if waiter > now
  #     setTimeout(doIt, waiter - now)
  #     waiter = Math.max(now, waiter) + 2000
  #   else
  #     doIt()
  #     waiter = now + 2000

  palava.browser.fixAudio = (videoWrapper) ->
    # nothing

else if palava.browser.isChrome()
  palava.browser.attachMediaStream = (element, stream) ->
    if stream
      $(element).prop 'src',  webkitURL.createObjectURL stream
    else
      $(element).each (key, el) -> el.pause()
      $(element).prop 'src', null

  # palava.browser.cloneMediaStream = (to, from) ->
  #   if $(from).prop("tagName") == 'VIDEO'
  #     $(to).prop 'src', $(from).prop('src')
  #     $(to).show()
  #     palava.browser.fixAudio $(from).parents('.plv-video-wrapper')
  #   else
  #     $(to).hide()

  palava.browser.fixAudio = (videoWrapper) ->
    if videoWrapper.attr('data-peer-muted') != 'true'
      $([200, 400, 1000, 2000, 4000, 8000, 16000]).each (_, n) -> # chrome bug
        setTimeout ( ->
          videoWrapper.find('.plv-video-mute').click()
          videoWrapper.find('.plv-video-mute').click()
        ), n

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
