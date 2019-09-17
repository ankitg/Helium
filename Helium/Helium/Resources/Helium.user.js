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
            document.getElementsByClassName('watch-area-inner')[0].style='padding: 0px !important';
            document.getElementsByClassName('watch-area-inner')[0].style='margin: 0px !important';
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

    // ErosNow keycodes
    isErosnow: function() {
        return document.location.toString().indexOf("erosnow.com") != -1
    },

    enTheatreMode: function() {
        if(!document.HELIUM_THEATREMODE) {
            document.getElementsByClassName('video-player')[0].style.width='100%';
            document.HELIUM_THEATREMODE = true;
        } else {
            document.getElementsByClassName('video-player')[0].style.width='85%';
            document.HELIUM_THEATREMODE = false;
        }
    },

    // Crunchyroll keycodes
    isCrunchyroll: function() {
        return document.location.toString().indexOf("crunchyroll.com") != -1
    },
    
    crTheatreMode: function() {
        
        if(!document.HELIUM_THEATREMODE) {
            // Hide externous elements
            document.getElementById('header_beta').style.display='none';
            document.getElementsByClassName('showmedia-trail')[0].style.display='none';
            document.getElementById('template_container').style.padding='0';
            document.getElementById('message_box').style.display='none';
            document.getElementById('showmedia').style.display='none';
            document.getElementById('footer').style.display='none';
            document.getElementById('template_scroller').style.padding='0';
            document.getElementsByClassName('cr-expo-banner')[0].style.display='none';
            
            // Make video player resizable
            document.getElementById('vilos-player').style.width = '100vw';
            document.getElementById('vilos-player').style.height = '100vh';
            
            document.HELIUM_THEATREMODE = true;
        } else {
            document.getElementById('header_beta').style.display='block';
            document.getElementsByClassName('showmedia-trail')[0].style.display='block';
            document.getElementById('message_box').style.display='block';
            document.getElementById('showmedia').style.display='block';
            document.getElementById('footer').style.display='block';

            document.HELIUM_THEATREMODE = false;
        }
    }

}

document.body.setAttribute('ondragstart','return false');
