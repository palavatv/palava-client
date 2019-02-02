# Change Log

## Next

* Use navigator.mediaDevices

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
