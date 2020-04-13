# palava | client

[palava](https://github.com/palavatv/palava) is a simplistic video chat website. It allows you to talk to your friends and colleagues from within your web browser. It is build on top of the [WebRTC](https://webrtc.org/) technology. No registration or browser plugin is required.

This repository contains the WebRTC client-side library of [palava.tv](https://palava.tv). It enables you to create PeerConnections to other browsers. Under the hood [adapter.js](https://github.com/webrtchacks/adapter) is used for the low-level functionality. The library implements the palava protocol to function together with the [SignalTower](https://github.com/farao/signaltower/) or the [PalavaMachine](https://github.com/palavatv/palava-machine) signaling servers. The [portal](https://github.com/palavatv/palava-portal) is a React web application that makes use of this library.

## Setup

Choose any of the following options

### 1) npm

    $ npm install palava-client

This will install palava and its dependencies into a sub directory. You'll need to include all dependencies (palava, eventEmitter, adapter.js) into your source file.

### 2) JS bundle file

Include a direct link to the source file into your HTML:

    <script src="https://path/to/palava.bundle.js" type="text/javascript"></script>

You can get it directly from the repository: https://github.com/palavatv/palava-client/blob/master/palava.bundle.js

It has all dependencies included.

### 3) Sprockets/Middleman

Alternatively, you can directly include the coffee files into your project. See the [palava portal](https://github.com/palavatv/palava-portal) for an example how to do so.

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
