# Change Log

## Next

* Add new method Peer.hasVideo() to check if video streams are available

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
