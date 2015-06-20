#!/bin/bash
cd static/js
cat external/jquery.min.js external/jquery-ui-1.8.2.custom.min.js external/jquery.mousewheel.min.js external/async.js external/shortcut.js simulation.js downloader.js friend.js spyglass.js overlay.js help.js > concat.js
