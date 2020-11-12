# Change Log

## 2.2.0

* Add support for TURN relays via signaltower
* Update webrtc-adapter to 7.7.0

## 2.1.0

* LocalPeer#{disable,enable}{Audio,Video}: Mute microphone / disable camera
  * Remove LocalPeer#toggleMute
* Add Peer#transmits{Audio,Video} check for enabled status of respective media
* Rework development rake tasks (de-namespace, add prepare_release)

## 2.0.1

* Fix that user media config would be ignored
* Remove Gum's detectMedia() method (use Peer's hasVideo / hasAudio instead)

## 2.0.0

### Breaking Changes

* Session#init renamed to Session#connect and will automatically join room when user media ready
* Session options flattened (no extra options key in options required/allowed)
* Client sends regular pings to socket server and expects pongs, or the connection will be ended
* Remove session option for custom channel and rename `web_socket_channel` to `webSocketAddress`
* Require adapter directly in palava-client and switch to `_no_edge` version

### Other

* Add userMediaConfig option to session options, so you can use it instead of having to create
  an identity
* Add session reconnect functionality
* Use adapter.js for browser detection + add browser.getUserAgentVersion
* Restrict automatic WebSocket connection retries to new connections
* Include more information session events:
  * local stream error objects
  * signaling error objects
  * add signaling_open event
  * add room_left event
* Add error types to signaling errors to be able to distinguish
* Remove old check that after 5 seconds unsuccessful server connection would be closed by client
* Avoid false positive "no webrtc support" messages when client is offline

## 1.10.1

* Send leave room event when closing connection

## 1.10.0

* Add automatic retries for WebSocket channel
* Update webrtc-adapter to 7.6.0

## 1.9.0

* Reset peer errors when connection state changes, but do not change ready-state
* Also add Peer.isRemote() convenience method

## 1.8.0

* Add new method Peer.hasVideo() to check if video streams are available
* Add new methods Peer.hasError() and Peer.getError() to check for peer's connection errors
* Deprecate: palava.browser.registerFullscreen()

## 1.7.1

* Also bump dependencies for... bower
* Remove another occurrence of jQuery

## 1.7.0

* Replace peer's stream_error event with ice connection_\* events
* Dependency bumps: webrtc-adapter to 7.5.1 and wolfy's eventemitter to 5.2.9
* Remove jQuery

## 1.6.0

* Remove old firefox hack
* Update internal webrtc api:
  * Fix ice url deprecation warning
  * Replace onaddstream api with new ontrack api
  * Drop empty ice candidates
  * Update jQuery to 3.x

## 1.5.0

* Use navigator.mediaDevices
* Add adapter.js and let it handle shims
* Update jQuery to latest 2.x (plan is to remove it)

## 1.4.0

* Support updated API for releasing user media
* Use URL instead of webkitURL for Chrome (fixes deprecation warning)
* Remove old WebRTC workarounds (palava.browser.patchSDP and palava.browser.fixAudio)

## 1.3.0

* Add version constants to palava library
* Peer audio stream fixes
* Remove partial support (Chrome <26)
* websocket: Fix setup of events to be able to detect initiation errors


## 1.2.0

* Be compatible with CommonJS, improve npm/bower packaging
* Make clear that jQuery is a dependency
* Bump EventEmitter dependency
* Add palava.RemotePeer.sendMessage() for custom signaling messages
* Support DataChannels
* Enforce right order of messages sent before the opening of the web socket


## 1.1.0

* Misc bug fixes
* Better namespacing approach
* Add docstrings
* Support TURN servers in a better way


## 1.0.0

* Initial public release
