
/*
palava v2.0.1 | LGPL | https://github.com/palavatv/palava-client

Copyright (C) 2014-2020 palava e. V.  contact@palava.tv

Copyright (C) 2013 Jan Lelis          hi@ruby.consulting
Copyright (C) 2013 Marius Melzer      marius@rasumi.net
Copyright (C) 2013 Stephan Thamm      stephan@innovailable.eu
Copyright (C) 2013 Kilian Ulbrich     kilian@innovailable.eu

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

(function() {


}).call(this);
(function() {
  this.palava = {
    browser: {}
  };

}).call(this);
(function() {
  if (typeof module === "object" && typeof module.exports === "object") {
    module.exports = this.palava;
  }

  if (typeof EventEmitter !== "object" && typeof require === "function") {
    this.EventEmitter = require('wolfy87-eventemitter');
  } else {
    this.EventEmitter = EventEmitter;
  }

  if (typeof adapter !== "object" && typeof require === "function") {
    this.adapter = require('webrtc-adapter/out/adapter_no_edge');
  } else {
    this.adapter = adapter;
  }

}).call(this);
(function() {
  var adapter, palava;

  palava = this.palava;

  adapter = this.adapter;

  palava.browser.isMozilla = function() {
    return adapter.browserDetails.browser === 'firefox';
  };

  palava.browser.isChrome = function() {
    return adapter.browserDetails.browser === 'chrome';
  };

  palava.browser.getUserAgent = function() {
    return adapter.browserDetails.browser;
  };

  palava.browser.getUserAgentVersion = function() {
    return adapter.browserDetails.version;
  };

  palava.browser.checkForWebrtcError = function() {
    var e;
    try {
      new window.RTCPeerConnection({
        iceServers: []
      });
    } catch (error) {
      e = error;
      return e;
    }
    return !(window.RTCPeerConnection && window.RTCIceCandidate && window.RTCSessionDescription && navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
  };

  palava.browser.getConstraints = function() {
    var constraints;
    constraints = {
      optional: [],
      mandatory: {
        OfferToReceiveAudio: true,
        OfferToReceiveVideo: true
      }
    };
    return constraints;
  };

  palava.browser.getPeerConnectionOptions = function() {
    if (palava.browser.isChrome()) {
      return {
        "optional": [
          {
            "DtlsSrtpKeyAgreement": true
          }
        ]
      };
    } else {
      return {};
    }
  };

  palava.browser.registerFullscreen = function(element, eventName) {
    console.log("DEPRECATED: palava.browser.registerFullscreen will be removed from the palava library in early 2021");
    if (element.requestFullscreen) {
      return element.addEventListener(eventName, function() {
        return this.requestFullscreen();
      });
    } else if (element.mozRequestFullScreen) {
      return element.addEventListener(eventName, function() {
        return this.mozRequestFullScreen();
      });
    } else if (element.webkitRequestFullscreen) {
      return element.addEventListener(eventName, function() {
        return this.webkitRequestFullscreen();
      });
    }
  };

  palava.browser.attachMediaStream = function(element, stream) {
    if (stream) {
      return element.srcObject = stream;
    } else {
      element.pause();
      return element.srcObject = null;
    }
  };

  palava.browser.attachPeer = function(element, peer) {
    var attach;
    attach = function() {
      palava.browser.attachMediaStream(element, peer.getStream());
      if (peer.isLocal()) {
        element.setAttribute('muted', true);
      }
      return element.play();
    };
    if (peer.getStream()) {
      return attach();
    } else {
      return peer.on('stream_ready', function() {
        return attach();
      });
    }
  };

}).call(this);
(function() {
  var palava,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  palava = this.palava;

  palava.Gum = (function(superClass) {
    extend(Gum, superClass);

    function Gum(config) {
      this.releaseStream = bind(this.releaseStream, this);
      this.getStream = bind(this.getStream, this);
      this.requestStream = bind(this.requestStream, this);
      this.changeConfig = bind(this.changeConfig, this);
      this.config = config || {
        video: true,
        audio: true
      };
      this.stream = null;
    }

    Gum.prototype.changeConfig = function(config) {
      this.config = config;
      this.releaseStream();
      return this.requestStream();
    };

    Gum.prototype.requestStream = function() {
      return navigator.mediaDevices.getUserMedia(this.config).then((function(_this) {
        return function(stream) {
          _this.stream = stream;
          return _this.emit('stream_ready', stream);
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          return _this.emit('stream_error', error);
        };
      })(this));
    };

    Gum.prototype.getStream = function() {
      return this.stream;
    };

    Gum.prototype.releaseStream = function() {
      if (this.stream) {
        this.stream.getAudioTracks().forEach((function(_this) {
          return function(track) {
            return track.stop();
          };
        })(this));
        this.stream.getVideoTracks().forEach((function(_this) {
          return function(track) {
            return track.stop();
          };
        })(this));
        this.stream = null;
        this.emit('stream_released', this);
        return true;
      } else {
        return false;
      }
    };

    return Gum;

  })(this.EventEmitter);

}).call(this);
(function() {
  var palava,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  palava = this.palava;

  palava.Identity = (function() {
    function Identity(o) {
      this.getStatus = bind(this.getStatus, this);
      this.getName = bind(this.getName, this);
      this.userMediaConfig = o.userMediaConfig;
      this.status = o.status || {};
      this.status.name = o.name;
    }

    Identity.prototype.newUserMedia = function() {
      return new palava.Gum(this.userMediaConfig);
    };

    Identity.prototype.getName = function() {
      return this.name;
    };

    Identity.prototype.getStatus = function() {
      return this.status;
    };

    return Identity;

  })();

}).call(this);
(function() {
  var palava,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  palava = this.palava;

  palava.Peer = (function(superClass) {
    extend(Peer, superClass);

    function Peer(id, status) {
      this.isRemote = bind(this.isRemote, this);
      this.isLocal = bind(this.isLocal, this);
      this.isReady = bind(this.isReady, this);
      this.isMuted = bind(this.isMuted, this);
      this.getError = bind(this.getError, this);
      this.hasError = bind(this.hasError, this);
      this.hasVideo = bind(this.hasVideo, this);
      this.hasAudio = bind(this.hasAudio, this);
      var base;
      this.id = id;
      this.status = status || {};
      (base = this.status).user_agent || (base.user_agent = palava.browser.getUserAgent());
      this.joinTime = (new Date()).getTime();
      this.ready = false;
      this.error = null;
    }

    Peer.prototype.hasAudio = function() {
      var ref, ref1;
      return ((ref = this.getStream()) != null ? (ref1 = ref.getAudioTracks()) != null ? ref1.length : void 0 : void 0) > 0;
    };

    Peer.prototype.hasVideo = function() {
      var ref, ref1;
      return ((ref = this.getStream()) != null ? (ref1 = ref.getVideoTracks()) != null ? ref1.length : void 0 : void 0) > 0;
    };

    Peer.prototype.hasError = function() {
      if (this.error) {
        return true;
      } else {
        return false;
      }
    };

    Peer.prototype.getError = function() {
      return this.error;
    };

    Peer.prototype.isMuted = function() {
      if (this.muted) {
        return true;
      } else {
        return false;
      }
    };

    Peer.prototype.isReady = function() {
      if (this.ready) {
        return true;
      } else {
        return false;
      }
    };

    Peer.prototype.isLocal = function() {
      if (this.local) {
        return true;
      } else {
        return false;
      }
    };

    Peer.prototype.isRemote = function() {
      if (this.local) {
        return false;
      } else {
        return true;
      }
    };

    return Peer;

  })(this.EventEmitter);

}).call(this);
(function() {
  var palava,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  palava = this.palava;

  palava.LocalPeer = (function(superClass) {
    extend(LocalPeer, superClass);

    function LocalPeer(id, status, room) {
      this.leave = bind(this.leave, this);
      this.toggleMute = bind(this.toggleMute, this);
      this.updateStatus = bind(this.updateStatus, this);
      this.getStream = bind(this.getStream, this);
      this.setupRoom = bind(this.setupRoom, this);
      this.setupUserMedia = bind(this.setupUserMedia, this);
      this.muted = true;
      this.local = true;
      LocalPeer.__super__.constructor.call(this, id, status);
      this.room = room;
      this.userMedia = room.userMedia;
      this.setupRoom();
      this.setupUserMedia();
    }

    LocalPeer.prototype.setupUserMedia = function() {
      this.userMedia.on('stream_released', (function(_this) {
        return function() {
          _this.ready = false;
          return _this.emit('stream_removed');
        };
      })(this));
      this.userMedia.on('stream_ready', (function(_this) {
        return function(e) {
          _this.ready = true;
          return _this.emit('stream_ready', e);
        };
      })(this));
      this.userMedia.on('stream_error', (function(_this) {
        return function(e) {
          return _this.emit('stream_error', e);
        };
      })(this));
      if (this.getStream()) {
        this.ready = true;
        return this.emit('stream_ready');
      }
    };

    LocalPeer.prototype.setupRoom = function() {
      this.room.peers[this.id] = this.room.localPeer = this;
      this.on('update', (function(_this) {
        return function() {
          return _this.room.emit('peer_update', _this);
        };
      })(this));
      this.on('stream_ready', (function(_this) {
        return function() {
          return _this.room.emit('peer_stream_ready', _this);
        };
      })(this));
      return this.on('stream_removed', (function(_this) {
        return function() {
          return _this.room.emit('peer_stream_removed', _this);
        };
      })(this));
    };

    LocalPeer.prototype.getStream = function() {
      return this.userMedia.getStream();
    };

    LocalPeer.prototype.updateStatus = function(status) {
      var base, key;
      if (!status || !(status instanceof Object) || Object.keys(status).length === 0) {
        return status;
      }
      for (key in status) {
        this.status[key] = status[key];
      }
      (base = this.status).user_agent || (base.user_agent = palava.browser.getUserAgent());
      this.room.channel.send({
        event: 'update_status',
        status: this.status
      });
      return this.status;
    };

    LocalPeer.prototype.toggleMute = function() {
      var i, len, muted, results, track, tracks;
      tracks = this.getStream.getAudioTracks();
      if (tracks.length === 0) {
        return;
      }
      muted = !tracks[0].enabled;
      results = [];
      for (i = 0, len = tracks.length; i < len; i++) {
        track = tracks[i];
        results.push(track.enabled = muted);
      }
      return results;
    };

    LocalPeer.prototype.leave = function() {
      this.ready = false;
      return this.emit('left');
    };

    return LocalPeer;

  })(palava.Peer);

}).call(this);
(function() {
  var palava,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  palava = this.palava;

  palava.Distributor = (function() {
    function Distributor(channel, peerId) {
      if (peerId == null) {
        peerId = null;
      }
      this.send = bind(this.send, this);
      this.on = bind(this.on, this);
      this.channel = channel;
      this.peerId = peerId;
    }

    Distributor.prototype.on = function(event, handler) {
      return this.channel.on('message', (function(_this) {
        return function(msg) {
          if (_this.peerId) {
            if (msg.sender_id === _this.peerId && event === msg.event) {
              return handler(msg);
            }
          } else {
            if (!msg.sender_id && event === msg.event) {
              return handler(msg);
            }
          }
        };
      })(this));
    };

    Distributor.prototype.send = function(msg) {
      var payload;
      if (this.peerId) {
        payload = {
          event: 'send_to_peer',
          peer_id: this.peerId,
          data: msg
        };
      } else {
        payload = msg;
      }
      return this.channel.send(payload);
    };

    return Distributor;

  })();

}).call(this);
(function() {
  var palava,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  palava = this.palava;

  palava.DataChannel = (function(superClass) {
    extend(DataChannel, superClass);

    DataChannel.prototype.MAX_BUFFER = 1024 * 1024;

    function DataChannel(channel) {
      this.channel = channel;
      this.channel.onmessage = (function(_this) {
        return function(event) {
          return _this.emit('message', event.data);
        };
      })(this);
      this.channel.onclose = (function(_this) {
        return function() {
          return _this.emit('close');
        };
      })(this);
      this.channel.onerror = (function(_this) {
        return function(e) {
          return _this.emit('error', e);
        };
      })(this);
      this.sendBuffer = [];
    }

    DataChannel.prototype.send = function(data, cb) {
      this.sendBuffer.push([data, cb]);
      if (this.sendBuffer.length === 1) {
        return this.actualSend();
      }
    };

    DataChannel.prototype.actualSend = function() {
      var cb, data, e, ref;
      if (this.channel.readyState !== 'open') {
        console.log("Not sending when not open!");
        return;
      }
      while (this.sendBuffer.length) {
        if (this.channel.bufferedAmount > this.MAX_BUFFER) {
          setTimeout(this.actualSend.bind(this), 1);
          return;
        }
        ref = this.sendBuffer[0], data = ref[0], cb = ref[1];
        try {
          this.channel.send(data);
        } catch (error) {
          e = error;
          setTimeout(this.actualSend.bind(this), 1);
          return;
        }
        try {
          if (typeof cb === "function") {
            cb();
          }
        } catch (error) {
          e = error;
          console.log('Exception in write callback:', e);
        }
        this.sendBuffer.shift();
      }
    };

    return DataChannel;

  })(this.EventEmitter);

}).call(this);
(function() {
  var palava,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  palava = this.palava;

  palava.RemotePeer = (function(superClass) {
    extend(RemotePeer, superClass);

    function RemotePeer(id, status, room, offers) {
      this.closePeerConnection = bind(this.closePeerConnection, this);
      this.oaError = bind(this.oaError, this);
      this.sdpSender = bind(this.sdpSender, this);
      this.sendMessage = bind(this.sendMessage, this);
      this.sendAnswer = bind(this.sendAnswer, this);
      this.sendOffer = bind(this.sendOffer, this);
      this.setupRoom = bind(this.setupRoom, this);
      this.setupDistributor = bind(this.setupDistributor, this);
      this.setupPeerConnection = bind(this.setupPeerConnection, this);
      this.generateIceOptions = bind(this.generateIceOptions, this);
      this.toggleMute = bind(this.toggleMute, this);
      this.getStream = bind(this.getStream, this);
      this.muted = false;
      this.local = false;
      RemotePeer.__super__.constructor.call(this, id, status);
      this.room = room;
      this.remoteStream = null;
      this.dataChannels = {};
      this.setupRoom();
      this.setupPeerConnection(offers);
      this.setupDistributor();
      if (offers) {
        this.sendOffer();
      }
    }

    RemotePeer.prototype.getStream = function() {
      return this.remoteStream;
    };

    RemotePeer.prototype.toggleMute = function() {
      return this.muted = !this.muted;
    };

    RemotePeer.prototype.generateIceOptions = function() {
      var options;
      options = [];
      if (this.room.options.stun) {
        options.push({
          urls: [this.room.options.stun]
        });
      }
      if (this.room.options.turn) {
        options.push({
          urls: [this.room.options.turn.url],
          username: this.room.options.turn.username,
          credential: this.room.options.turn.password
        });
      }
      return {
        iceServers: options
      };
    };

    RemotePeer.prototype.setupPeerConnection = function(offers) {
      var channel, label, options, ref, registerChannel;
      this.peerConnection = new RTCPeerConnection(this.generateIceOptions(), palava.browser.getPeerConnectionOptions());
      this.peerConnection.onicecandidate = (function(_this) {
        return function(event) {
          if (event.candidate) {
            return _this.distributor.send({
              event: 'ice_candidate',
              sdpmlineindex: event.candidate.sdpMLineIndex,
              sdpmid: event.candidate.sdpMid,
              candidate: event.candidate.candidate
            });
          }
        };
      })(this);
      this.peerConnection.ontrack = (function(_this) {
        return function(event) {
          _this.remoteStream = event.streams[0];
          _this.ready = true;
          return _this.emit('stream_ready');
        };
      })(this);
      this.peerConnection.onremovestream = (function(_this) {
        return function(event) {
          _this.remoteStream = null;
          _this.ready = false;
          return _this.emit('stream_removed');
        };
      })(this);
      this.peerConnection.oniceconnectionstatechange = (function(_this) {
        return function(event) {
          var connectionState;
          connectionState = event.target.iceConnectionState;
          switch (connectionState) {
            case 'connecting':
              _this.error = null;
              return _this.emit('connection_pending');
            case 'connected':
              _this.error = null;
              return _this.emit('connection_established');
            case 'failed':
              _this.error = "connection_failed";
              return _this.emit('connection_failed');
            case 'disconnected':
              _this.error = "connection_disconnected";
              return _this.emit('connection_disconnected');
            case 'closed':
              _this.error = "connection_closed";
              return _this.emit('connection_closed');
          }
        };
      })(this);
      if (this.room.localPeer.getStream()) {
        this.peerConnection.addStream(this.room.localPeer.getStream());
      } else {

      }
      if (this.room.options.dataChannels != null) {
        registerChannel = (function(_this) {
          return function(channel) {
            var name, wrapper;
            name = channel.label;
            wrapper = new palava.DataChannel(channel);
            _this.dataChannels[name] = wrapper;
            return _this.emit('channel_ready', name, wrapper);
          };
        })(this);
        if (offers) {
          ref = this.room.options.dataChannels;
          for (label in ref) {
            options = ref[label];
            channel = this.peerConnection.createDataChannel(label, options);
            channel.onopen = function() {
              return registerChannel(this);
            };
          }
        } else {
          this.peerConnection.ondatachannel = (function(_this) {
            return function(event) {
              return registerChannel(event.channel);
            };
          })(this);
        }
      }
      return this.peerConnection;
    };

    RemotePeer.prototype.setupDistributor = function() {
      this.distributor = new palava.Distributor(this.room.channel, this.id);
      this.distributor.on('peer_left', (function(_this) {
        return function(msg) {
          if (_this.ready) {
            _this.remoteStream = null;
            _this.emit('stream_removed');
            _this.ready = false;
          }
          _this.peerConnection.close();
          return _this.emit('left');
        };
      })(this));
      this.distributor.on('ice_candidate', (function(_this) {
        return function(msg) {
          var candidate;
          if (msg.candidate === "") {
            return;
          }
          candidate = new RTCIceCandidate({
            candidate: msg.candidate,
            sdpMLineIndex: msg.sdpmlineindex,
            sdpMid: msg.sdpmid
          });
          return _this.peerConnection.addIceCandidate(candidate);
        };
      })(this));
      this.distributor.on('offer', (function(_this) {
        return function(msg) {
          _this.peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp));
          _this.emit('offer');
          return _this.sendAnswer();
        };
      })(this));
      this.distributor.on('answer', (function(_this) {
        return function(msg) {
          _this.peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp));
          return _this.emit('answer');
        };
      })(this));
      this.distributor.on('peer_updated_status', (function(_this) {
        return function(msg) {
          _this.status = msg.status;
          return _this.emit('update');
        };
      })(this));
      this.distributor.on('message', (function(_this) {
        return function(msg) {
          return _this.emit('message', msg.data);
        };
      })(this));
      return this.distributor;
    };

    RemotePeer.prototype.setupRoom = function() {
      this.room.peers[this.id] = this;
      this.on('left', (function(_this) {
        return function() {
          delete _this.room.peers[_this.id];
          return _this.room.emit('peer_left', _this);
        };
      })(this));
      this.on('offer', (function(_this) {
        return function() {
          return _this.room.emit('peer_offer', _this);
        };
      })(this));
      this.on('answer', (function(_this) {
        return function() {
          return _this.room.emit('peer_answer', _this);
        };
      })(this));
      this.on('update', (function(_this) {
        return function() {
          return _this.room.emit('peer_update', _this);
        };
      })(this));
      this.on('stream_ready', (function(_this) {
        return function() {
          return _this.room.emit('peer_stream_ready', _this);
        };
      })(this));
      this.on('stream_removed', (function(_this) {
        return function() {
          return _this.room.emit('peer_stream_removed', _this);
        };
      })(this));
      this.on('connection_pending', (function(_this) {
        return function() {
          return _this.room.emit('peer_connection_pending', _this);
        };
      })(this));
      this.on('connection_established', (function(_this) {
        return function() {
          return _this.room.emit('peer_connection_established', _this);
        };
      })(this));
      this.on('connection_failed', (function(_this) {
        return function() {
          return _this.room.emit('peer_connection_failed', _this);
        };
      })(this));
      this.on('connection_disconnected', (function(_this) {
        return function() {
          return _this.room.emit('peer_connection_disconnected', _this);
        };
      })(this));
      this.on('connection_closed', (function(_this) {
        return function() {
          return _this.room.emit('peer_connection_closed', _this);
        };
      })(this));
      this.on('oaerror', (function(_this) {
        return function(e) {
          return _this.room.emit('peer_oaerror', _this, e);
        };
      })(this));
      return this.on('channel_ready', (function(_this) {
        return function(n, c) {
          return _this.room.emit('peer_channel_ready', _this, n, c);
        };
      })(this));
    };

    RemotePeer.prototype.sendOffer = function() {
      return this.peerConnection.createOffer(this.sdpSender('offer'), this.oaError, palava.browser.getConstraints());
    };

    RemotePeer.prototype.sendAnswer = function() {
      return this.peerConnection.createAnswer(this.sdpSender('answer'), this.oaError, palava.browser.getConstraints());
    };

    RemotePeer.prototype.sendMessage = function(data) {
      return this.distributor.send({
        event: 'message',
        data: data
      });
    };

    RemotePeer.prototype.sdpSender = function(event) {
      return (function(_this) {
        return function(sdp) {
          _this.peerConnection.setLocalDescription(sdp);
          return _this.distributor.send({
            event: event,
            sdp: sdp
          });
        };
      })(this);
    };

    RemotePeer.prototype.oaError = function(error) {
      return this.emit('oaerror', error);
    };

    RemotePeer.prototype.closePeerConnection = function() {
      var ref;
      if ((ref = this.peerConnection) != null) {
        ref.close();
      }
      return this.peerConnection = null;
    };

    return RemotePeer;

  })(palava.Peer);

}).call(this);
(function() {
  var palava,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  palava = this.palava;

  palava.Room = (function(superClass) {
    extend(Room, superClass);

    function Room(roomId, channel, userMedia, options) {
      if (options == null) {
        options = {};
      }
      this.getAllPeers = bind(this.getAllPeers, this);
      this.getRemotePeers = bind(this.getRemotePeers, this);
      this.getLocalPeer = bind(this.getLocalPeer, this);
      this.getPeerById = bind(this.getPeerById, this);
      this.destroy = bind(this.destroy, this);
      this.leave = bind(this.leave, this);
      this.join = bind(this.join, this);
      this.setupDistributor = bind(this.setupDistributor, this);
      this.setupOptions = bind(this.setupOptions, this);
      this.setupUserMedia = bind(this.setupUserMedia, this);
      this.id = roomId;
      this.userMedia = userMedia;
      this.channel = channel;
      this.peers = {};
      this.options = options;
      this.setupUserMedia();
      this.setupDistributor();
      this.setupOptions();
    }

    Room.prototype.setupUserMedia = function() {
      this.userMedia.on('stream_ready', (function(_this) {
        return function(stream) {
          return _this.emit('local_stream_ready', stream);
        };
      })(this));
      this.userMedia.on('stream_error', (function(_this) {
        return function(error) {
          return _this.emit('local_stream_error', error);
        };
      })(this));
      return this.userMedia.on('stream_released', (function(_this) {
        return function() {
          return _this.emit('local_stream_removed');
        };
      })(this));
    };

    Room.prototype.setupOptions = function() {
      var base, base1;
      (base = this.options).joinTimeout || (base.joinTimeout = 1000);
      return (base1 = this.options).ownStatus || (base1.ownStatus = {});
    };

    Room.prototype.setupDistributor = function() {
      this.distributor = new palava.Distributor(this.channel);
      this.distributor.on('joined_room', (function(_this) {
        return function(msg) {
          var i, len, newPeer, offers, peer, ref;
          clearTimeout(_this.joinCheckTimeout);
          new palava.LocalPeer(msg.own_id, _this.options.ownStatus, _this);
          ref = msg.peers;
          for (i = 0, len = ref.length; i < len; i++) {
            peer = ref[i];
            offers = !palava.browser.isChrome();
            newPeer = new palava.RemotePeer(peer.peer_id, peer.status, _this, offers);
          }
          return _this.emit("joined", _this);
        };
      })(this));
      this.distributor.on('new_peer', (function(_this) {
        return function(msg) {
          var newPeer, offers;
          offers = msg.status.user_agent === 'chrome';
          newPeer = new palava.RemotePeer(msg.peer_id, msg.status, _this, offers);
          return _this.emit('peer_joined', newPeer);
        };
      })(this));
      this.distributor.on('error', (function(_this) {
        return function(msg) {
          return _this.emit('signaling_error', 'server', msg.description);
        };
      })(this));
      return this.distributor.on('shutdown', (function(_this) {
        return function(msg) {
          return _this.emit('signaling_shutdown', msg.seconds);
        };
      })(this));
    };

    Room.prototype.join = function(status) {
      var base, i, key, len;
      if (status == null) {
        status = {};
      }
      this.joinCheckTimeout = setTimeout(((function(_this) {
        return function() {
          return _this.emit('join_error');
        };
      })(this)), this.options.joinTimeout);
      for (i = 0, len = status.length; i < len; i++) {
        key = status[i];
        this.options.ownStatus[key] = status[key];
      }
      (base = this.options.ownStatus).user_agent || (base.user_agent = palava.browser.getUserAgent());
      return this.distributor.send({
        event: 'join_room',
        room_id: this.id,
        status: this.options.ownStatus
      });
    };

    Room.prototype.leave = function() {
      if (this.channel) {
        this.distributor.send({
          event: 'leave_room'
        });
      }
      return this.emit('left');
    };

    Room.prototype.destroy = function() {
      this.getRemotePeers().forEach((function(_this) {
        return function(peer) {
          return peer.closePeerConnection();
        };
      })(this));
      return clearTimeout(this.joinCheckTimeout);
    };

    Room.prototype.getPeerById = function(id) {
      return this.peers[id];
    };

    Room.prototype.getLocalPeer = function() {
      return this.localPeer;
    };

    Room.prototype.getRemotePeers = function() {
      return this.getAllPeers(false);
    };

    Room.prototype.getAllPeers = function(allowLocal) {
      var id, peer, peers, ref;
      if (allowLocal == null) {
        allowLocal = true;
      }
      peers = [];
      ref = this.peers;
      for (id in ref) {
        peer = ref[id];
        if (allowLocal || !peer.local) {
          peers.push(peer);
        }
      }
      return peers;
    };

    return Room;

  })(this.EventEmitter);

}).call(this);
(function() {
  var palava,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  palava = this.palava;

  palava.WebSocketChannel = (function(superClass) {
    extend(WebSocketChannel, superClass);

    function WebSocketChannel(address, retries) {
      if (retries == null) {
        retries = 2;
      }
      this.close = bind(this.close, this);
      this.send = bind(this.send, this);
      this.startClientPings = bind(this.startClientPings, this);
      this.setupWebsocket = bind(this.setupWebsocket, this);
      this.sendDeliverOnConnectMessages = bind(this.sendDeliverOnConnectMessages, this);
      this.isConnected = bind(this.isConnected, this);
      this.address = address;
      this.retries = retries;
      this.messagesToDeliverOnConnect = [];
      this.setupWebsocket();
      this.startClientPings();
    }

    WebSocketChannel.prototype.isConnected = function() {
      var ref;
      return ((ref = this.socket) != null ? ref.readyState : void 0) === 1;
    };

    WebSocketChannel.prototype.sendDeliverOnConnectMessages = function() {
      var i, len, msg, ref;
      ref = this.messagesToDeliverOnConnect;
      for (i = 0, len = ref.length; i < len; i++) {
        msg = ref[i];
        this.socket.send(msg);
      }
      return this.messagesToDeliverOnConnect = [];
    };

    WebSocketChannel.prototype.setupWebsocket = function() {
      this.socket = new WebSocket(this.address);
      this.socket.onopen = (function(_this) {
        return function(handshake) {
          _this.retries = 0;
          _this.sendDeliverOnConnectMessages();
          return _this.emit('open', handshake);
        };
      })(this);
      this.socket.onmessage = (function(_this) {
        return function(msg) {
          var parsedMsg;
          try {
            parsedMsg = JSON.parse(msg.data);
            if (parsedMsg.event === "pong") {
              return _this.outstandingPongs = 0;
            } else {
              return _this.emit('message', parsedMsg);
            }
          } catch (error) {
            return _this.emit('error', 'invalid_format', msg.data);
          }
        };
      })(this);
      this.socket.onerror = (function(_this) {
        return function(msg) {
          clearInterval(_this.pingInterval);
          if (_this.retries > 0) {
            _this.retries -= 1;
            _this.setupWebsocket();
            return _this.startClientPings();
          } else {
            return _this.emit('error', 'socket', msg);
          }
        };
      })(this);
      return this.socket.onclose = (function(_this) {
        return function() {
          clearInterval(_this.pingInterval);
          return _this.emit('close');
        };
      })(this);
    };

    WebSocketChannel.prototype.startClientPings = function() {
      this.outstandingPongs = 0;
      return this.pingInterval = setInterval((function(_this) {
        return function() {
          if (_this.outstandingPongs >= 6) {
            clearInterval(_this.pingInterval);
            _this.socket.close();
            _this.emit('error', "missing_pongs");
          }
          _this.socket.send(JSON.stringify({
            event: "ping"
          }));
          return _this.outstandingPongs += 1;
        };
      })(this), 5000);
    };

    WebSocketChannel.prototype.send = function(data) {
      if (this.socket.readyState === 1) {
        if (this.messagesToDeliverOnConnect.length !== 0) {
          this.sendDeliverOnConnectMessages();
        }
        return this.socket.send(JSON.stringify(data));
      } else if (this.socket.readyState > 1) {
        return this.emit('not_reachable');
      } else {
        return this.messagesToDeliverOnConnect.push(JSON.stringify(data));
      }
    };

    WebSocketChannel.prototype.close = function() {
      return this.socket.close();
    };

    return WebSocketChannel;

  })(this.EventEmitter);

}).call(this);
(function() {
  var palava,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  palava = this.palava;

  palava.Session = (function(superClass) {
    extend(Session, superClass);

    function Session(o) {
      this.destroy = bind(this.destroy, this);
      this.createRoom = bind(this.createRoom, this);
      this.createChannel = bind(this.createChannel, this);
      this.getRoom = bind(this.getRoom, this);
      this.getUserMedia = bind(this.getUserMedia, this);
      this.getChannel = bind(this.getChannel, this);
      this.checkRequirements = bind(this.checkRequirements, this);
      this.assignOptions = bind(this.assignOptions, this);
      this.tearDown = bind(this.tearDown, this);
      this.reconnect = bind(this.reconnect, this);
      this.connect = bind(this.connect, this);
      this.roomOptions = {};
      this.assignOptions(o);
    }

    Session.prototype.connect = function(o) {
      this.assignOptions(o);
      if (!this.checkRequirements()) {
        return;
      }
      this.createChannel();
      this.createRoom();
      if (this.userMedia.stream) {
        return this.room.join();
      } else {
        return this.userMedia.requestStream().then((function(_this) {
          return function() {
            return _this.room.join();
          };
        })(this));
      }
    };

    Session.prototype.reconnect = function() {
      this.emit('session_reconnect');
      this.tearDown();
      this.createChannel();
      this.createRoom();
      return this.room.join();
    };

    Session.prototype.tearDown = function(resetUserMedia) {
      var ref, ref1, ref2, ref3, ref4, ref5;
      if (resetUserMedia == null) {
        resetUserMedia = false;
      }
      if ((ref = this.room) != null) {
        ref.removeAllListeners();
      }
      if ((ref1 = this.channel) != null) {
        ref1.removeAllListeners();
      }
      if ((ref2 = this.channel) != null ? ref2.isConnected() : void 0) {
        if ((ref3 = this.room) != null) {
          ref3.leave();
        }
      }
      if ((ref4 = this.channel) != null) {
        ref4.close();
      }
      this.channel = null;
      if ((ref5 = this.room) != null) {
        ref5.destroy();
      }
      this.room = null;
      if (resetUserMedia && this.userMedia) {
        return this.userMedia.releaseStream();
      }
    };

    Session.prototype.assignOptions = function(o) {
      if (o.roomId) {
        this.roomId = o.roomId;
      }
      if (o.webSocketAddress) {
        this.webSocketAddress = o.webSocketAddress;
      }
      if (o.identity) {
        this.userMedia = o.identity.newUserMedia();
        this.roomOptions.ownStatus = o.identity.getStatus();
      }
      if (o.userMediaConfig) {
        this.userMedia = new palava.Gum(o.userMediaConfig);
      }
      if (o.dataChannels) {
        this.roomOptions.dataChannels = o.dataChannels;
      }
      if (o.stun) {
        this.roomOptions.stun = o.stun;
      }
      if (o.turn) {
        this.roomOptions.turn = o.turn;
      }
      if (o.joinTimeout) {
        return this.roomOptions.joinTimeout = o.joinTimeout;
      }
    };

    Session.prototype.checkRequirements = function() {
      var e;
      if (!this.webSocketAddress) {
        this.emit('argument_error', 'no web socket address given');
        return false;
      }
      if (!this.userMedia) {
        this.emit('argument_error', 'no user media given');
        return false;
      }
      if (!this.roomId) {
        this.emit('argument_error', 'no room id given');
        return false;
      }
      if (!this.roomOptions.stun) {
        this.emit('argument_error', 'no stun server given');
        return false;
      }
      if (!navigator.onLine) {
        this.emit('signaling_not_reachable');
        return false;
      }
      if (e = palava.browser.checkForWebrtcError()) {
        this.emit('webrtc_no_support', 'WebRTC is not supported by your browser', e);
        return false;
      }
      return true;
    };

    Session.prototype.getChannel = function() {
      return this.channel;
    };

    Session.prototype.getUserMedia = function() {
      return this.userMedia;
    };

    Session.prototype.getRoom = function() {
      return this.room;
    };

    Session.prototype.createChannel = function() {
      this.channel = new palava.WebSocketChannel(this.webSocketAddress);
      this.channel.on('open', (function(_this) {
        return function() {
          return _this.emit('signaling_open');
        };
      })(this));
      this.channel.on('error', (function(_this) {
        return function(t, e) {
          return _this.emit('signaling_error', t, e);
        };
      })(this));
      this.channel.on('close', (function(_this) {
        return function(e) {
          return _this.emit('signaling_close', e);
        };
      })(this));
      return this.channel.on('not_reachable', (function(_this) {
        return function() {
          return _this.emit('signaling_not_reachable');
        };
      })(this));
    };

    Session.prototype.createRoom = function() {
      this.room = new palava.Room(this.roomId, this.channel, this.userMedia, this.roomOptions);
      this.room.on('local_stream_ready', (function(_this) {
        return function(s) {
          return _this.emit('local_stream_ready', s);
        };
      })(this));
      this.room.on('local_stream_error', (function(_this) {
        return function(e) {
          return _this.emit('local_stream_error', e);
        };
      })(this));
      this.room.on('local_stream_removed', (function(_this) {
        return function() {
          return _this.emit('local_stream_removed');
        };
      })(this));
      this.room.on('join_error', (function(_this) {
        return function() {
          _this.tearDown(true);
          return _this.emit('room_join_error', _this.room);
        };
      })(this));
      this.room.on('full', (function(_this) {
        return function() {
          return _this.emit('room_full', _this.room);
        };
      })(this));
      this.room.on('joined', (function(_this) {
        return function() {
          return _this.emit('room_joined', _this.room);
        };
      })(this));
      this.room.on('left', (function(_this) {
        return function() {
          return _this.emit('room_left', _this.room);
        };
      })(this));
      this.room.on('peer_joined', (function(_this) {
        return function(p) {
          return _this.emit('peer_joined', p);
        };
      })(this));
      this.room.on('peer_offer', (function(_this) {
        return function(p) {
          return _this.emit('peer_offer', p);
        };
      })(this));
      this.room.on('peer_answer', (function(_this) {
        return function(p) {
          return _this.emit('peer_answer', p);
        };
      })(this));
      this.room.on('peer_update', (function(_this) {
        return function(p) {
          return _this.emit('peer_update', p);
        };
      })(this));
      this.room.on('peer_stream_ready', (function(_this) {
        return function(p) {
          return _this.emit('peer_stream_ready', p);
        };
      })(this));
      this.room.on('peer_stream_removed', (function(_this) {
        return function(p) {
          return _this.emit('peer_stream_removed', p);
        };
      })(this));
      this.room.on('peer_connection_pending', (function(_this) {
        return function(p) {
          return _this.emit('peer_connection_pending', p);
        };
      })(this));
      this.room.on('peer_connection_established', (function(_this) {
        return function(p) {
          return _this.emit('peer_connection_established', p);
        };
      })(this));
      this.room.on('peer_connection_failed', (function(_this) {
        return function(p) {
          return _this.emit('peer_connection_failed', p);
        };
      })(this));
      this.room.on('peer_connection_disconnected', (function(_this) {
        return function(p) {
          return _this.emit('peer_connection_disconnected', p);
        };
      })(this));
      this.room.on('peer_connection_closed', (function(_this) {
        return function(p) {
          return _this.emit('peer_connection_closed', p);
        };
      })(this));
      this.room.on('peer_left', (function(_this) {
        return function(p) {
          return _this.emit('peer_left', p);
        };
      })(this));
      this.room.on('peer_channel_ready', (function(_this) {
        return function(p, n, c) {
          return _this.emit('peer_channel_ready', p, n, c);
        };
      })(this));
      this.room.on('signaling_shutdown', (function(_this) {
        return function(p) {
          return _this.emit('signaling_shutdown', p);
        };
      })(this));
      this.room.on('signaling_error', (function(_this) {
        return function(t, e) {
          return _this.emit('signaling_error', t, e);
        };
      })(this));
      return true;
    };

    Session.prototype.destroy = function() {
      this.emit('session_before_destroy');
      this.tearDown(true);
      return this.emit('session_after_destroy');
    };

    return Session;

  })(this.EventEmitter);

}).call(this);
(function() {
  var palava;

  palava = this.palava;

  palava.PROTOCOL_NAME = 'palava';

  palava.PROTOCOL_VERSION = '1.0.0';

  palava.LIB_VERSION = '2.0.1';

  palava.LIB_COMMIT = 'v2.0.1-0-gb51e215678-dirty';

  palava.protocol_identifier = function() {
    return palava.PROTOCOL_NAME = "palava.1.0";
  };

}).call(this);
