/*
palava v1.0.0 | LGPL | https://github.com/palavatv/palava-client

Copyright (C) 2013 Jan Lelis       jan@signaling.io
Copyright (C) 2013 Marius Melzer   marius@signaling.io
Copyright (C) 2013 Stephan Thamm   thammi@chaossource.net
Copyright (C) 2013 Kilian Ulbrich  kilian@innovailable.eu

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
  var palava;

  this.palava = palava = {
    browser: {}
  };

}).call(this);
(function() {
  palava.browser.PeerConnection = window.PeerConnection || window.webkitPeerConnection00 || window.webkitRTCPeerConnection || window.mozRTCPeerConnection;

  palava.browser.IceCandidate = window.mozRTCIceCandidate || window.RTCIceCandidate;

  palava.browser.SessionDescription = window.mozRTCSessionDescription || window.RTCSessionDescription;

  palava.browser.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia;

  palava.browser.isMozilla = function() {
    if (window.mozRTCPeerConnection) {
      return true;
    } else {
      return false;
    }
  };

  palava.browser.isChrome = function() {
    return /Chrome/i.test(navigator.userAgent);
  };

  palava.browser.getUserAgent = function() {
    if (palava.browser.isMozilla()) {
      return 'firefox';
    } else if (palava.browser.isChrome()) {
      return 'chrome';
    } else {
      return 'unknown';
    }
  };

  palava.browser.checkForWebrtcError = function() {
    var e;
    try {
      new palava.browser.PeerConnection({
        iceServers: []
      });
    } catch (_error) {
      e = _error;
      return e;
    }
    return !(palava.browser.PeerConnection && palava.browser.IceCandidate && palava.browser.SessionDescription && palava.browser.getUserMedia);
  };

  palava.browser.chromeVersion = function() {
    var matches, version, _;
    matches = /Chrome\/(\d+)/i.exec(navigator.userAgent);
    if (matches) {
      _ = matches[0], version = matches[1];
      return parseInt(version);
    } else {
      return false;
    }
  };

  palava.browser.checkForPartialSupport = function() {
    return palava.browser.isChrome() && palava.browser.chromeVersion() < 26;
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
    if (palava.browser.isMozilla()) {
      constraints.mandatory.MozDontOfferDataChannel = true;
    }
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

  palava.browser.patchSDP = function(sdp) {
    var chars, crypto, i, key, _i, _j, _k, _results, _results1;
    if (palava.browser.isChrome() && palava.browser.chromeVersion() >= 31) {
      return sdp;
    }
    chars = (function() {
      _results1 = [];
      for (_j = 33; _j <= 58; _j++){ _results1.push(_j); }
      return _results1;
    }).apply(this).concat((function() {
      _results = [];
      for (_i = 60; _i <= 126; _i++){ _results.push(_i); }
      return _results;
    }).apply(this)).map(function(a) {
      return String.fromCharCode(a);
    });
    key = '';
    for (i = _k = 0; _k < 40; i = ++_k) {
      key += chars[Math.floor(Math.random() * chars.length)];
    }
    crypto = 'a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:' + key + '\r\nc=IN';
    if (sdp.sdp.indexOf('a=crypto') === -1) {
      sdp.sdp = sdp.sdp.replace(/c=IN/g, crypto);
    }
    return sdp;
  };

  palava.browser.registerFullscreen = function(element, eventName) {
    if (element[0].requestFullscreen) {
      return element.on(eventName, function() {
        return this.requestFullscreen();
      });
    } else if (element[0].mozRequestFullScreen) {
      return element.on(eventName, function() {
        return this.mozRequestFullScreen();
      });
    } else if (element[0].webkitRequestFullscreen) {
      return element.on(eventName, function() {
        return this.webkitRequestFullscreen();
      });
    }
  };

  if (palava.browser.isMozilla()) {
    palava.browser.attachMediaStream = function(element, stream) {
      if (stream) {
        return $(element).prop('mozSrcObject', stream);
      } else {
        $(element).each(function(key, el) {
          return el.pause();
        });
        return $(element).prop('mozSrcObject', null);
      }
    };
    palava.browser.fixAudio = function(videoWrapper) {};
  } else if (palava.browser.isChrome()) {
    palava.browser.attachMediaStream = function(element, stream) {
      if (stream) {
        return $(element).prop('src', webkitURL.createObjectURL(stream));
      } else {
        $(element).each(function(key, el) {
          return el.pause();
        });
        return $(element).prop('src', null);
      }
    };
    palava.browser.fixAudio = function(videoWrapper) {
      if (videoWrapper.attr('data-peer-muted') !== 'true') {
        return $([200, 400, 1000, 2000, 4000, 8000, 16000]).each(function(_, n) {
          return setTimeout((function() {
            videoWrapper.find('.plv-video-mute').click();
            return videoWrapper.find('.plv-video-mute').click();
          }), n);
        });
      }
    };
  }

}).call(this);
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  palava.Gum = (function(_super) {
    __extends(Gum, _super);

    function Gum(config) {
      this.releaseStream = __bind(this.releaseStream, this);
      this.getStream = __bind(this.getStream, this);
      this.requestStream = __bind(this.requestStream, this);
      this.detectMedia = __bind(this.detectMedia, this);
      this.changeConfig = __bind(this.changeConfig, this);
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

    Gum.prototype.detectMedia = function() {
      this.config = {
        video: false,
        audio: false
      };
      if (this.stream.getVideoTracks().length > 0) {
        this.config.video = true;
      }
      if (this.stream.getAudioTracks().length > 0) {
        return this.config.audio = true;
      }
    };

    Gum.prototype.requestStream = function() {
      var _this = this;
      palava.browser.getUserMedia.call(navigator, this.config, function(stream) {
        _this.stream = stream;
        _this.detectMedia();
        return _this.emit('stream_ready', _this);
      }, function() {
        return _this.emit('stream_error', _this);
      });
      return true;
    };

    Gum.prototype.getStream = function() {
      return this.stream;
    };

    Gum.prototype.releaseStream = function() {
      if (this.stream) {
        this.stream.stop();
        this.stream = null;
        this.emit('stream_released', this);
        return true;
      } else {
        return false;
      }
    };

    return Gum;

  })(EventEmitter);

}).call(this);
(function() {
  palava.Identity = (function() {
    function Identity(o) {
      this.userMediaConfig = o.userMediaConfig;
      this.name = o.name;
    }

    Identity.prototype.newUserMedia = function() {
      return new palava.Gum(this.userMediaConfig);
    };

    Identity.prototype.getName = function() {
      return this.name;
    };

    return Identity;

  })();

}).call(this);
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  palava.Peer = (function(_super) {
    __extends(Peer, _super);

    function Peer(id, status) {
      this.isLocal = __bind(this.isLocal, this);
      this.isReady = __bind(this.isReady, this);
      this.isMuted = __bind(this.isMuted, this);
      this.hasAudio = __bind(this.hasAudio, this);
      var _base;
      this.id = id;
      this.status = status || {};
      (_base = this.status).user_agent || (_base.user_agent = palava.browser.getUserAgent());
      this.joinTime = (new Date()).getTime();
    }

    Peer.prototype.hasAudio = function() {
      return palava.browser.checkForPartialSupport() || this.getStream() && this.getStream().getAudioTracks().length;
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

    return Peer;

  })(EventEmitter);

}).call(this);
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  palava.LocalPeer = (function(_super) {
    __extends(LocalPeer, _super);

    function LocalPeer(id, status, room) {
      this.leave = __bind(this.leave, this);
      this.toggleMute = __bind(this.toggleMute, this);
      this.hasAudio = __bind(this.hasAudio, this);
      this.updateStatus = __bind(this.updateStatus, this);
      this.getStream = __bind(this.getStream, this);
      this.setupRoom = __bind(this.setupRoom, this);
      this.setupUserMedia = __bind(this.setupUserMedia, this);
      this.muted = true;
      this.local = true;
      LocalPeer.__super__.constructor.call(this, id, status);
      this.room = room;
      this.userMedia = room.userMedia;
      this.setupRoom();
      this.setupUserMedia();
    }

    LocalPeer.prototype.setupUserMedia = function() {
      var _this = this;
      this.userMedia.on('stream_released', function() {
        _this.ready = false;
        return _this.emit('stream_removed');
      });
      this.userMedia.on('stream_ready', function(e) {
        _this.ready = true;
        return _this.emit('stream_ready', e);
      });
      this.userMedia.on('stream_error', function(e) {
        return _this.emit('stream_error', e);
      });
      if (this.getStream()) {
        this.ready = true;
        return this.emit('stream_ready');
      }
    };

    LocalPeer.prototype.setupRoom = function() {
      var _this = this;
      this.room.peers[this.id] = this.room.localPeer = this;
      this.on('update', function() {
        return _this.room.emit('peer_update', _this);
      });
      this.on('stream_ready', function() {
        return _this.room.emit('peer_stream_ready', _this);
      });
      return this.on('stream_removed', function() {
        return _this.room.emit('peer_stream_removed', _this);
      });
    };

    LocalPeer.prototype.getStream = function() {
      return this.userMedia.getStream();
    };

    LocalPeer.prototype.updateStatus = function(status) {
      var key, _base;
      if (!status || !(status instanceof Object) || Object.keys(status).length === 0) {
        return status;
      }
      for (key in status) {
        this.status[key] = status[key];
      }
      (_base = this.status).user_agent || (_base.user_agent = palava.browser.getUserAgent());
      this.room.channel.send({
        event: 'update_status',
        status: this.status
      });
      return this.status;
    };

    LocalPeer.prototype.hasAudio = function() {
      var stream;
      if (stream = this.getStream) {
        return stream.getAudioTracks.length() > 0;
      }
      return false;
    };

    LocalPeer.prototype.toggleMute = function() {
      return this.userMedia.changeConfig({
        video: this.userMedia.config.video,
        audio: !this.userMedia.config.audio
      });
    };

    LocalPeer.prototype.leave = function() {
      this.ready = false;
      return this.emit('left');
    };

    return LocalPeer;

  })(palava.Peer);

}).call(this);
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  palava.Distributor = (function() {
    function Distributor(channel, peerId) {
      if (peerId == null) {
        peerId = null;
      }
      this.send = __bind(this.send, this);
      this.on = __bind(this.on, this);
      this.channel = channel;
      this.peerId = peerId;
    }

    Distributor.prototype.on = function(event, handler) {
      var _this = this;
      return this.channel.on('message', function(msg) {
        if (_this.peerId) {
          if (msg.sender_id === _this.peerId && event === msg.event) {
            return handler(msg);
          }
        } else {
          if (!msg.sender_id && event === msg.event) {
            return handler(msg);
          }
        }
      });
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
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  palava.RemotePeer = (function(_super) {
    __extends(RemotePeer, _super);

    function RemotePeer(id, status, room) {
      this.mozillaCheckAddStream = __bind(this.mozillaCheckAddStream, this);
      this.oaError = __bind(this.oaError, this);
      this.sdpSender = __bind(this.sdpSender, this);
      this.sendAnswer = __bind(this.sendAnswer, this);
      this.sendOffer = __bind(this.sendOffer, this);
      this.setupRoom = __bind(this.setupRoom, this);
      this.setupDistributor = __bind(this.setupDistributor, this);
      this.setupPeerConnection = __bind(this.setupPeerConnection, this);
      this.generateIceOptions = __bind(this.generateIceOptions, this);
      this.toggleMute = __bind(this.toggleMute, this);
      this.hasAudio = __bind(this.hasAudio, this);
      this.getStream = __bind(this.getStream, this);
      this.muted = false;
      this.local = false;
      RemotePeer.__super__.constructor.call(this, id, status);
      this.room = room;
      this.remoteStream = null;
      this.setupRoom();
      this.setupPeerConnection();
      this.setupDistributor();
    }

    RemotePeer.prototype.getStream = function() {
      return this.remoteStream;
    };

    RemotePeer.prototype.hasAudio = function() {
      return this.remoteStream && (palava.browser.checkForPartialSupport() || this.remoteStream.getAudioTracks().length);
    };

    RemotePeer.prototype.toggleMute = function() {
      return this.muted = !this.muted;
    };

    RemotePeer.prototype.generateIceOptions = function() {
      var options;
      options = [];
      if (this.room.options.stun) {
        options.push({
          url: this.room.options.stun
        });
      }
      if (this.room.options.turn) {
        options.push({
          url: this.room.options.turn.url,
          username: this.room.options.turn.username,
          credential: this.room.options.turn.password
        });
      }
      return {
        iceServers: options
      };
    };

    RemotePeer.prototype.setupPeerConnection = function() {
      var _this = this;
      this.peerConnection = new palava.browser.PeerConnection(this.generateIceOptions(), palava.browser.getPeerConnectionOptions());
      this.peerConnection.onicecandidate = function(event) {
        if (event.candidate) {
          return _this.distributor.send({
            event: 'ice_candidate',
            sdpmlineindex: event.candidate.sdpMLineIndex,
            sdpmid: event.candidate.sdpMid,
            candidate: event.candidate.candidate
          });
        }
      };
      this.peerConnection.onaddstream = function(event) {
        _this.remoteStream = event.stream;
        _this.ready = true;
        return _this.emit('stream_ready');
      };
      this.peerConnection.onremovestream = function(event) {
        _this.remoteStream = null;
        _this.ready = false;
        return _this.emit('stream_removed');
      };
      this.peerConnection.oniceconnectionstatechange = function(event) {
        var connectionState;
        connectionState = event.target.iceConnectionState;
        if (connectionState === 'failed') {
          return _this.emit('stream_error');
        }
      };
      if (this.room.localPeer.getStream()) {
        this.peerConnection.addStream(this.room.localPeer.getStream());
      } else {

      }
      return this.peerConnection;
    };

    RemotePeer.prototype.setupDistributor = function() {
      var _this = this;
      this.distributor = new palava.Distributor(this.room.channel, this.id);
      this.distributor.on('peer_left', function(msg) {
        if (_this.ready) {
          _this.remoteStream = null;
          _this.emit('stream_removed');
          _this.ready = false;
        }
        _this.peerConnection.close();
        return _this.emit('left');
      });
      this.distributor.on('ice_candidate', function(msg) {
        var candidate;
        candidate = new palava.browser.IceCandidate({
          candidate: msg.candidate,
          sdpMLineIndex: msg.sdpmlineindex,
          sdpMid: msg.sdpmid
        });
        return _this.peerConnection.addIceCandidate(candidate);
      });
      this.distributor.on('offer', function(msg) {
        _this.peerConnection.setRemoteDescription(new palava.browser.SessionDescription(msg.sdp));
        _this.emit('offer');
        return _this.sendAnswer();
      });
      this.distributor.on('answer', function(msg) {
        _this.peerConnection.setRemoteDescription(new palava.browser.SessionDescription(msg.sdp));
        return _this.emit('answer');
      });
      this.distributor.on('peer_updated_status', function(msg) {
        _this.status = msg.status;
        return _this.emit('update');
      });
      return this.distributor;
    };

    RemotePeer.prototype.setupRoom = function() {
      var _this = this;
      this.room.peers[this.id] = this;
      this.on('left', function() {
        delete _this.room.peers[_this.id];
        return _this.room.emit('peer_left', _this);
      });
      this.on('offer', function() {
        return _this.room.emit('peer_offer', _this);
      });
      this.on('answer', function() {
        return _this.room.emit('peer_answer', _this);
      });
      this.on('update', function() {
        return _this.room.emit('peer_update', _this);
      });
      this.on('stream_ready', function() {
        return _this.room.emit('peer_stream_ready', _this);
      });
      this.on('stream_error', function() {
        return _this.room.emit('peer_stream_error', _this);
      });
      this.on('stream_removed', function() {
        return _this.room.emit('peer_stream_removed', _this);
      });
      return this.on('oaerror', function(e) {
        return _this.room.emit('peer_oaerror', _this, e);
      });
    };

    RemotePeer.prototype.sendOffer = function() {
      this.peerConnection.createOffer(this.sdpSender('offer'), this.oaError, palava.browser.getConstraints());
      return this.mozillaCheckAddStream();
    };

    RemotePeer.prototype.sendAnswer = function() {
      this.peerConnection.createAnswer(this.sdpSender('answer'), this.oaError, palava.browser.getConstraints());
      return this.mozillaCheckAddStream();
    };

    RemotePeer.prototype.sdpSender = function(event) {
      var _this = this;
      return function(sdp) {
        sdp = palava.browser.patchSDP(sdp);
        _this.peerConnection.setLocalDescription(sdp);
        return _this.distributor.send({
          event: event,
          sdp: sdp
        });
      };
    };

    RemotePeer.prototype.oaError = function(error) {
      return this.emit('oaerror', error);
    };

    RemotePeer.prototype.mozillaCheckAddStream = function() {
      var timeouts,
        _this = this;
      if (palava.browser.isMozilla()) {
        return timeouts = $([100, 200, 400, 1000, 2000, 4000, 8000, 12000, 16000]).map(function(_, n) {
          return setTimeout((function() {
            var remoteTrack;
            if (remoteTrack = (_this.peerConnection.remoteStreams && _this.peerConnection.remoteStreams[0]) || (_this.peerConnection.getRemoteStreams() && _this.peerConnection.getRemoteStreams()[0])) {
              timeouts.each(function(_, t) {
                return clearTimeout(t);
              });
              return _this.peerConnection.onaddstream({
                stream: remoteTrack
              });
            }
          }), n);
        });
      }
    };

    return RemotePeer;

  })(palava.Peer);

}).call(this);
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  palava.Room = (function(_super) {
    __extends(Room, _super);

    function Room(roomId, channel, userMedia, options) {
      if (options == null) {
        options = {};
      }
      this.getAllPeers = __bind(this.getAllPeers, this);
      this.getRemotePeers = __bind(this.getRemotePeers, this);
      this.getLocalPeer = __bind(this.getLocalPeer, this);
      this.getPeerById = __bind(this.getPeerById, this);
      this.leave = __bind(this.leave, this);
      this.join = __bind(this.join, this);
      this.setupDistributor = __bind(this.setupDistributor, this);
      this.setupOptions = __bind(this.setupOptions, this);
      this.setupChannel = __bind(this.setupChannel, this);
      this.setupUserMedia = __bind(this.setupUserMedia, this);
      this.id = roomId;
      this.userMedia = userMedia;
      this.channel = channel;
      this.peers = {};
      this.options = options;
      this.setupUserMedia();
      this.setupChannel();
      this.setupDistributor();
      this.setupOptions();
    }

    Room.prototype.setupUserMedia = function() {
      var _this = this;
      this.userMedia.on('stream_ready', function(event) {
        return _this.emit('local_stream_ready', event.stream);
      });
      this.userMedia.on('stream_error', function(event) {
        return _this.emit('local_stream_error', event.stream);
      });
      return this.userMedia.on('stream_released', function() {
        return _this.emit('local_stream_removed');
      });
    };

    Room.prototype.setupChannel = function() {
      var _this = this;
      this.channel.on('not_reachable', function(e) {
        return _this.emit('signaling_not_reachable', e);
      });
      this.channel.on('error', function(e) {
        return _this.emit('signaling_error', e);
      });
      return this.channel.on('close', function(e) {
        return _this.emit('signaling_close', e);
      });
    };

    Room.prototype.setupOptions = function() {
      var _base, _base1;
      (_base = this.options).joinTimeout || (_base.joinTimeout = 1000);
      return (_base1 = this.options).ownStatus || (_base1.ownStatus = {});
    };

    Room.prototype.setupDistributor = function() {
      var _this = this;
      this.distributor = new palava.Distributor(this.channel);
      this.distributor.on('joined_room', function(msg) {
        var newPeer, peer, _i, _len, _ref;
        clearTimeout(_this.joinCheckTimeout);
        new palava.LocalPeer(msg.own_id, _this.options.ownStatus, _this);
        _ref = msg.peers;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          peer = _ref[_i];
          newPeer = new palava.RemotePeer(peer.peer_id, peer.status, _this);
          if (!palava.browser.isChrome()) {
            newPeer.sendOffer();
          }
        }
        return _this.emit("joined", _this);
      });
      this.distributor.on('new_peer', function(msg) {
        var newPeer;
        newPeer = new palava.RemotePeer(msg.peer_id, msg.status, _this);
        if (msg.status.user_agent === 'chrome') {
          newPeer.sendOffer();
        }
        return _this.emit('peer_joined', newPeer);
      });
      this.distributor.on('error', function(msg) {
        return _this.emit('signaling_error', msg.message);
      });
      return this.distributor.on('shutdown', function(msg) {
        return _this.emit('signaling_shutdown', msg.seconds);
      });
    };

    Room.prototype.join = function(status) {
      var key, _base, _i, _len,
        _this = this;
      if (status == null) {
        status = {};
      }
      this.joinCheckTimeout = setTimeout((function() {
        _this.emit('join_error', 'Not able to join room');
        return _this.leave();
      }), this.options.joinTimeout);
      for (_i = 0, _len = status.length; _i < _len; _i++) {
        key = status[_i];
        this.options.ownStatus[key] = status[key];
      }
      (_base = this.options.ownStatus).user_agent || (_base.user_agent = palava.browser.getUserAgent());
      return this.distributor.send({
        event: 'join_room',
        room_id: this.id,
        status: this.options.ownStatus
      });
    };

    Room.prototype.leave = function() {
      this.emit('leave');
      this.channel && this.channel.close();
      return this.localPeer && this.localPeer.stream && this.localPeer.stream.close();
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
      var id, peer, peers, _ref;
      if (allowLocal == null) {
        allowLocal = true;
      }
      peers = [];
      _ref = this.peers;
      for (id in _ref) {
        peer = _ref[id];
        if (allowLocal || !peer.local) {
          peers.push(peer);
        }
      }
      return peers;
    };

    return Room;

  })(EventEmitter);

}).call(this);
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  palava.WebSocketChannel = (function(_super) {
    __extends(WebSocketChannel, _super);

    function WebSocketChannel(address) {
      this.close = __bind(this.close, this);
      this.send_or_retry = __bind(this.send_or_retry, this);
      this.send = __bind(this.send, this);
      this.setupEvents = __bind(this.setupEvents, this);
      var _this = this;
      this.reached = false;
      this.socket = new WebSocket(address);
      this.socket.onopen = function(handshake) {
        _this.setupEvents();
        return _this.emit('open', handshake);
      };
    }

    WebSocketChannel.prototype.setupEvents = function() {
      var _this = this;
      this.socket.onmessage = function(msg) {
        var SyntaxError;
        try {
          return _this.emit('message', JSON.parse(msg.data));
        } catch (_error) {
          SyntaxError = _error;
          return _this.emit('error_invalid_json', msg);
        }
      };
      this.socket.onerror = function(msg) {
        return _this.emit('error', msg);
      };
      return this.socket.onclose = function() {
        return _this.emit('close');
      };
    };

    WebSocketChannel.prototype.send = function(data) {
      return this.send_or_retry(data, 3);
    };

    WebSocketChannel.prototype.send_or_retry = function(data, retries) {
      var _this = this;
      if (retries === 0) {
        return this.emit('not_reachable', this.serverAddress);
      } else if (this.reached || this.socket.readyState === 1) {
        this.reached = true;
        return this.socket.send(JSON.stringify(data));
      } else {
        return setTimeout((function() {
          return _this.send_or_retry(data, retries - 1);
        }), 400);
      }
    };

    WebSocketChannel.prototype.close = function() {
      return this.socket.close();
    };

    return WebSocketChannel;

  })(EventEmitter);

}).call(this);
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  palava.Session = (function(_super) {
    __extends(Session, _super);

    function Session(o) {
      this.destroy = __bind(this.destroy, this);
      this.setupRoom = __bind(this.setupRoom, this);
      this.getRoom = __bind(this.getRoom, this);
      this.getUserMedia = __bind(this.getUserMedia, this);
      this.getChannel = __bind(this.getChannel, this);
      this.checkRequirements = __bind(this.checkRequirements, this);
      this.assignOptions = __bind(this.assignOptions, this);
      this.init = __bind(this.init, this);
      this.channel = null;
      this.userMedia = null;
      this.roomId = null;
      this.roomOptions = {};
      this.assignOptions(o);
    }

    Session.prototype.init = function(o) {
      this.assignOptions(o);
      this.checkRequirements();
      this.setupRoom();
      return this.userMedia.requestStream();
    };

    Session.prototype.assignOptions = function(o) {
      this.roomId = o.roomId || this.roomId;
      if (o.channel) {
        this.channel = o.channel;
      } else if (o.web_socket_channel) {
        this.channel = new palava.WebSocketChannel(o.web_socket_channel);
      }
      if (o.identity) {
        this.userMedia = o.identity.newUserMedia();
        this.roomOptions.ownStatus = {
          name: o.identity.getName()
        };
      }
      if (o.options) {
        this.roomOptions.stun = o.options.stun || this.roomOptions.stun;
        this.roomOptions.turn = o.options.turn || this.roomOptions.turn;
        return this.roomOptions.joinTimeout = o.options.joinTimeout || this.roomOptions.joinTimeout;
      }
    };

    Session.prototype.checkRequirements = function() {
      var e;
      if (!this.channel) {
        this.emit('argument_error', 'no channel given');
        return;
      }
      if (!this.userMedia) {
        this.emit('argument_error', 'no user media given');
        return;
      }
      if (!this.roomId) {
        this.emit('argument_error', 'no room id given');
        return;
      }
      if (!this.roomOptions.stun) {
        this.emit('argument_error', 'no stun server given');
        return;
      }
      if (e = palava.browser.checkForWebrtcError()) {
        this.emit('webrtc_no_support', 'WebRTC is not supported by your browser', e);
        return;
      }
      if (palava.browser.checkForPartialSupport()) {
        return this.emit('webrtc_partial_support');
      }
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

    Session.prototype.setupRoom = function() {
      var _this = this;
      this.room = new palava.Room(this.roomId, this.channel, this.userMedia, this.roomOptions);
      this.room.on('local_stream_ready', function(s) {
        return _this.emit('local_stream_ready', s);
      });
      this.room.on('local_stream_error', function(s) {
        return _this.emit('local_stream_error');
      });
      this.room.on('local_stream_removed', function() {
        return _this.emit('local_stream_removed');
      });
      this.room.on('join_error', function(e) {
        return _this.emit('room_join_error', _this.room, e);
      });
      this.room.on('full', function() {
        return _this.emit('room_full', _this.room);
      });
      this.room.on('joined', function() {
        return _this.emit('room_joined', _this.room);
      });
      this.room.on('peer_joined', function(p) {
        return _this.emit('peer_joined', p);
      });
      this.room.on('peer_offer', function(p) {
        return _this.emit('peer_offer', p);
      });
      this.room.on('peer_answer', function(p) {
        return _this.emit('peer_answer', p);
      });
      this.room.on('peer_update', function(p) {
        return _this.emit('peer_update', p);
      });
      this.room.on('peer_stream_ready', function(p) {
        return _this.emit('peer_stream_ready', p);
      });
      this.room.on('peer_stream_error', function(p) {
        return _this.emit('peer_stream_error', p);
      });
      this.room.on('peer_stream_removed', function(p) {
        return _this.emit('peer_stream_removed', p);
      });
      this.room.on('peer_left', function(p) {
        return _this.emit('peer_left', p);
      });
      this.room.on('signaling_shutdown', function(p) {
        return _this.emit('signaling_shutdown', p);
      });
      this.room.on('signaling_close', function(p) {
        return _this.emit('signaling_close', p);
      });
      this.room.on('signaling_error', function(p) {
        return _this.emit('signaling_error', p);
      });
      this.room.on('signaling_not_reachable', function(p) {
        return _this.emit('signaling_not_reachable', p);
      });
      return true;
    };

    Session.prototype.destroy = function() {
      this.emit('session_before_destroy');
      this.room && this.room.leave();
      this.channel && this.channel.close();
      this.userMedia && this.userMedia.releaseStream();
      return this.emit('session_after_destroy');
    };

    return Session;

  })(EventEmitter);

}).call(this);
(function() {
  palava.PROTOCOL_NAME = 'palava';

  palava.PROTOCOL_VERSION = '1.0.0';

  palava.protocol_identifier = function() {
    return palava.PROTOCOL_NAME = "palava.1.0";
  };

}).call(this);
