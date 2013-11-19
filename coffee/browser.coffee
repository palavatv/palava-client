namespace 'palava.browser', (exports) ->
  exports.PeerConnection     = window.PeerConnection || window.webkitPeerConnection00 || window.webkitRTCPeerConnection || window.mozRTCPeerConnection
  exports.IceCandidate       = window.mozRTCIceCandidate || window.RTCIceCandidate
  exports.SessionDescription = window.mozRTCSessionDescription || window.RTCSessionDescription
  exports.getUserMedia       = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia

  exports.isMozilla = ->
    if window.mozRTCPeerConnection then true
    else false

  exports.isChrome = ->
    /Chrome/i.test(navigator.userAgent)

  exports.getUserAgent = ->
    if exports.isMozilla()
      'firefox'
    else if exports.isChrome()
      'chrome'
    else
      'unknown'

  exports.checkForWebrtcError = ->
    try
      new exports.PeerConnection({iceServers: []})
    catch e
      return e

    !( exports.PeerConnection && exports.IceCandidate && exports.SessionDescription && exports.getUserMedia)

  exports.chromeVersion = ->
    matches =  /Chrome\/(\d+)/i.exec(navigator.userAgent)
    if matches
      [_, version] = matches
      parseInt(version)
    else
      false

  exports.checkForPartialSupport = ->
    exports.isChrome() && exports.chromeVersion() < 26

  exports.getConstraints = () ->
    constraints =
      optional: []
      mandatory:
        OfferToReceiveAudio: true
        OfferToReceiveVideo: true
    if exports.isMozilla()
      constraints.mandatory.MozDontOfferDataChannel = true
    constraints

  exports.getPeerConnectionOptions = () ->
    if exports.isChrome()
      {"optional": [{"DtlsSrtpKeyAgreement": true}]}
    else
      {}

  exports.patchSDP = (sdp) ->
    return sdp if exports.isChrome() && exports.chromeVersion() >= 31
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

  exports.registerFullscreen = (element, eventName) ->
    if(element[0].requestFullscreen)
      element.on eventName, -> this.requestFullscreen()
    else if(element[0].mozRequestFullScreen)
      element.on eventName, -> this.mozRequestFullScreen()
    else if(element[0].webkitRequestFullscreen)
      element.on eventName, -> this.webkitRequestFullscreen()

  if exports.isMozilla()
    exports.attachMediaStream = (element, stream) ->
      if stream
        $(element).prop 'mozSrcObject',  stream
      else
        $(element).prop 'mozSrcObject', null

    # waiter = 0
    # exports.cloneMediaStream = (to, from) ->
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

    exports.fixAudio = (videoWrapper) ->
      # nothing

  else if exports.isChrome()
    exports.attachMediaStream = (element, stream) ->
      if stream
        $(element).prop 'src',  webkitURL.createObjectURL stream
      else
        $(element).prop 'src', null

    # exports.cloneMediaStream = (to, from) ->
    #   if $(from).prop("tagName") == 'VIDEO'
    #     $(to).prop 'src', $(from).prop('src')
    #     $(to).show()
    #     exports.fixAudio $(from).parents('.plv-video-wrapper')
    #   else
    #     $(to).hide()

    exports.fixAudio = (videoWrapper) ->
      if videoWrapper.attr('data-peer-muted') != 'true'
        $([200, 400, 1000, 2000, 4000, 8000, 16000]).each (_, n) -> # chrome bug
          setTimeout ( ->
            videoWrapper.find('.plv-video-mute').click()
            videoWrapper.find('.plv-video-mute').click()
          ), n