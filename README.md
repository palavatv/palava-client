# palava | client

[palava](https://github.com/palavatv/palava) is a simplistic video chat website. It allows you to talk to your friends and colleagues from within your web browser. It is build on top of the [WebRTC](https://webrtc.org/) technology. No registration or browser plugin is required.

This repository contains the WebRTC client-side library of [palava.tv](https://palava.tv). It enables you to create PeerConnections to other browsers. [webrtc-adapter](https://github.com/webrtchacks/adapter) is used for the low-level functionality. The library implements the palava protocol to function together with the [signaltower](https://github.com/palavatv/signaltower/) or the [palava-machine](https://github.com/palavatv/palava-machine) signaling servers.

## Setup

### npm / yarn

    $ npm install palava-client

This will install palava and its dependencies into the node_modules folder. You'll need to include all dependencies (palava, eventEmitter, adapter.js) into your source file.

### JS bundle file

Include a direct link to the bundle file (which has all dependencies included) into your HTML:

    <script src="https://path/to/palava.bundle.js" type="text/javascript"></script>

You can get it from here: https://raw.githubusercontent.com/palavatv/palava-client/master/palava.bundle.js

## API Docs

https://palavatv.github.io/palava-client/

## Credits

LGPLv3. Part of the [palava project](https://palava.tv).

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
