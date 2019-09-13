// ==UserScript==
// @include        *
// ==/UserScript==

var __Helium = {
    _seek: function(delta) {
        document.getElementsByTagName('video')[0].currentTime += delta;
    },

    _volume: function (delta) {
        document.getElementsByTagName('video')[0].volume += delta;
    },

    seekBackward: function () {
        __Helium._seek(-3);
    },

    seekForward: function () {
        __Helium._seek(3);
    },

    volumeUp: function () {
        __Helium._volume(+0.15);
    },

    volumeDown: function() {
        __Helium._volume(-0.15);
    },

    playPause: function () {
        var player = document.getElementsByTagName('video')[0];
        player.paused ? player.play() : player.pause();
    },

    documentHeight: function () {
        var body = document.body, html = document.documentElement;

        return Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight);
    },

    hasVideotag: function () {
        return document.getElementsByTagName('video').length != 0;
    },
    
    // Hotstar keycodes
    isHotstar: function() {
        return document.location.toString().indexOf("hotstar.com") != -1
    },
    
    hsTheatreMode: function() {
        if(!document.HELIUM_THEATREMODE) {
            document.getElementsByClassName('header-container')[0].style='display: none';
            document.getElementsByClassName('detail-area')[0].style='display: none';
            document.getElementsByClassName('tray-area')[0].style='display: none';
            document.getElementsByClassName('footer')[0].style='display: none';
            document.getElementsByClassName('watch-area-inner')[0].style='margin: 0px';
            document.getElementsByClassName('watch-area-inner')[0].style='padding: 0px';
            document.HELIUM_THEATREMODE = true;
        } else {
            document.getElementsByClassName('header-container')[0].style='display: block';
            document.getElementsByClassName('detail-area')[0].style='display: block';
            document.getElementsByClassName('tray-area')[0].style='display: block';
            document.getElementsByClassName('footer')[0].style='display: block';
            document.getElementsByClassName('watch-area-inner')[0].style='margin: 0 auto';
            document.getElementsByClassName('watch-area-inner')[0].style='padding: 10px';
            document.HELIUM_THEATREMODE = false;
        }
    },
    
    hsPlayPause: function() {
        var player = videojs('my_video_1');
        if(player.paused()) {
            player.play();
        } else {
            player.pause();
        }
    },
    
    // Crunchyroll keycodes
    isCrunchyroll: function() {
        return document.location.toString().indexOf("crunchyroll.com") != -1
    }

}

document.body.setAttribute('ondragstart','return false');
