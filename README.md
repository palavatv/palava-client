# palava

palava is a WebRTC library for the browser. It enables you to create PeerConnections to other browsers. It works together with [palava-machine](https://github.com/palavatv/palava-machine), an open source WebRTC signaling server written in Ruby. To see it in action, checkout [palava.tv](https://palava.tv) ([source](https://github.com/palavatv/palava-portal)).

## Setup

palava is written in [CoffeeScript](http://coffeescript.org/). However, if you want to only use it (not hack on it), just use option 1 or 2 to include the compiled JavaScript version:

### 1) bower

    $ bower install palava

For more information on bower, see [bower.io](http://bower.io/)

### 2) Direct JS File

Include a direct link to the source file into your HTML:

<script src="https://assets.palava.tv/js/palava.min.js" type="text/javascript"></script>

### 3) Sprockets/Middleman

Alternatively, directly include the coffee files into your project. See the [palava portal](https://github.com/palavatv/palava-portal) for how it is done.


## Usage

All features are namespaced into "palava" or "palava.browser". More documentation will be added.


## Credits

LGPLv3. Part of the [palava project](https://palava.tv).

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
