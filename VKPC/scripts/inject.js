// VKPC for Chrome and Safari

(function(vkpc_sid) {
if (!window.VKPC) {

var _debug = window.__vkpc_debug || true;

if (!document.addEventListener) {
  window.console && console.log("[VKPC] an outdated browser detected, very strange, plz update");
  return;
}

var browser = (function() {
  var ua = navigator.userAgent.toLowerCase();
  var browser = {
    id: null,
    chrome: false,
    safari: false,
    yandex: false,
    firefox: false,
    opera: false
  };

  if (/opr/i.test(ua) && /chrome/i.test(ua)) {
    browser.opera = true;
    browser.id = 3;
  } else if (/yabrowser/i.test(ua) && /chrome/i.test(ua)) {
    browser.yandex = true;
    browser.id = 4;
  } else if (/firefox|iceweasel/i.test(ua)) {
    browser.firefox = true;
    browser.id = 1;
  } else if (!(/chrome/i.test(ua)) && /webkit|safari|khtml/i.test(ua)) {
    browser.safari = true;
    browser.id = 2;
  } else if (/chrome/i.test(ua)) {
    browser.chrome = true;
    browser.id = 0;
  }

  return browser;
})();

// functions
(function(window, document) {
  var queue = [], done = false, _top = true, root = document.documentElement, eventsAdded = false;

  function init(e) {
    if (e.type == 'readystatechange' && document.readyState != 'complete') return;
    (e.type == 'load' ? window : document).removeEventListener(e.type, init);
    if (!done) {
      done = true;
      while (queue.length) {
        queue.shift().call(window);
      }
    }
  }
  function poll() {
    try {
      root.doScroll('left');
    } catch (e) {
      setTimeout(poll, 50);
      return;
    }
    init('poll');
  }

  window.DOMContentLoaded = function(fn) {
    if (document.readyState == 'complete' || done) {
      fn.call(window);
    } else {
      queue.push(fn);

      if (!eventsAdded) {
        if (document.createEventObject && root.doScroll) {
          try {
            _top = !window.frameElement;
          } catch (e) {}
          if (_top) poll();
        }

        document.addEventListener('DOMContentLoaded', init);
        document.addEventListener('readystatechange', init);
        window.addEventListener('load', init);
      }
    }
  }
})(window, document);

function log() {
  if (!_debug)
    return;
  var args = Array.prototype.slice.call(arguments);
  args.unshift(window.VKPC ? '[VKPC '+window.VKPC.getSID()+']' : '[VKPC]');
  try {
    window.console && console.log.apply(console, args);
  } catch (e) {}
}
function trim(string) {
  return string.replace(/(^\s+)|(\s+$)/g, "");
}
function startsWith(str, needle) {
  return str.indexOf(needle) == 0;
}
function endsWith(str, suffix) {
  return str.indexOf(suffix, str.length - suffix.length) !== -1;
}
function random(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
function shuffle(o) {
  for (var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
  return o;
}
function getStackTrace(split) {
  split = split === undefined ? true : split;
  try {
    o.lo.lo += 0;
  } catch(e) {
    if (e.stack) {
      return split ? e.stack.split('\n') : e.stack;
    }
  }
  return null;
}
function buildQueryString(obj) {
  var list = [], i;
  for (i in obj) {
    list.push(encodeURIComponent(i) + '=' + encodeURIComponent(obj[i]));
  }
  return list.join('&');
}
function stripTags(html) {
  var div = document.createElement("div");
  div.innerHTML = html;
  return div.textContent || div.innerText || "";
}
function decodeEntities(value) {
  var textarea = document.createElement('textarea');
  textarea.innerHTML = value;
  return textarea.value;
}
function extend(dest, source) {
  for (var i in source) {
    dest[i] = source[i];
  }
  return dest;
}
function intval(value) {
  if (value === true) return 1;
  return parseInt(value) || 0;
}

var WSC_STATE_NONE = 'NONE',
    WSC_STATE_OK = 'OK',
    WSC_STATE_CLOSED = 'CLOSED',
    WSC_STATE_ERR = 'ERR';
function WSClient(address, protocol, opts) {
  this.state = WSC_STATE_NONE;
  this._ws = null;

  this.address = address;
  this.protocol = protocol;

  this._onmessage = opts.onmessage;
  this._onclose = opts.onclose;
  this._onerror = opts.onerror;
  this._onopen = opts.onopen;

  this._pingTimer = null;
  this._reconnectTimer = null;
}
extend(WSClient.prototype, {
  connect: function() {
    this.state = WSC_STATE_NONE;
    var self = this;

    var _websocket = window.WebSocket || window.MozWebSocket;
    if (!_websocket) {
      log('[WSClient connect] websockets are not supported');
      return;
    }

    this._ws = new _websocket(this.address, this.protocol);
    this._ws.onopen = function() {
      self.state = WSC_STATE_OK;
      self._setTimers();
      self._onopen && self._onopen.apply(self);
    };
    this._ws.onerror = function() {
      self._unsetTimers();
      if (self.state != WSC_STATE_ERR) {
        self.state = WSC_STATE_ERR;
      }
      self._onerror && self._onerror.apply(self);
    };
    this._ws.onclose = function() {
      self._unsetTimers();
      if (self.state != WSC_STATE_ERR) {
        self.state = WSC_STATE_ERR;
      }
      self._onclose && self._onclose.apply(self);
    };
    this._ws.onmessage = function(e) {
      self._onmessage && self._onmessage.apply(self, [e.data]);
    };
  },
  close: function() {
    this._unsetTimers();
    this._ws.close();
  },
  reconnect: function() {
    var self = this;
    if (this.state == WSC_STATE_OK) {
      log('[WSClient reconnect] state = '+this.state+', why reconnect?');
      return;
    }
    clearTimeout(this._reconnectTimer);
    this._reconnectTimer = setTimeout(function() {
      self.connect();
    }, 3000);
  },
  send: function(obj) {
    obj._browser = browser.id;
    var self = this;
    this._waitForConnection(function() {
      self._ws.send(JSON.stringify(obj));
    }, 200);
  },
  _setTimers: function() {
    var self = this;
    this._pingTimer = setInterval(function() {
      try {
        self._ws.send("PING");
      } catch (e) {
        log('[WSClient _pingTimer]', e);
      }
    }, 30000);
  },
  _unsetTimers: function() {
    clearInterval(this._pingTimer);
  },
  _waitForConnection: function(callback, interval) {
    if (this._ws.readyState === 1) {
      callback();
    } else {
      var self = this;
      setTimeout(function() {
        self._waitForConnection(callback, interval);
      }, interval);
    }
  }
});

var client = new WSClient("wss://vkpc-local.ch1p.com:56130", "signaling-protocol", {
  onopen: function() {
    this.send({command: 'setBrowser'});
  },
  onmessage: function(cmd) {
    // pass
  },
  onerror: function() {
    this.reconnect();
  },
  onclose: function() {
    this.reconnect();
  }
});
client.connect();

window.VKPC = new function() {
  var _sid = null;
  var _currentTrackId = null;
  var _lastPlaylistSummary = null;
  var _lastPlaylistId = 0;
  var _operateQueue = [];
  var _setTrackIdTimeout = null;
  var _watchGraphicsChange = false;
  var _checkPlaylistTimer = null;

  function wrapAudioMethods() {
    // var self = this;
    if (window.audioPlayer) {
      if (!audioPlayer.__operate) {
        audioPlayer.__operate = audioPlayer.operate;
        audioPlayer.operate = function(id, nextPlaylist, opts) {
          var currentId = audioPlayer.id, _status = id != currentId  ? 'play' : null;
          audioPlayer.__operate.apply(audioPlayer, arguments);
          //self.firstOperateAfterPlaylistUpdating = false;
          log('operate(), arguments:', arguments);

          if (existsInCurrentPlaylist(id)) {
            log('operate(), found in current pl, setTrackId() now');
            setTrackId(id, _status);
          } else {
            log('operate(), not found, setToOperateQueue() now');
            setToOperateQueue(id, _status);
          }
        };
      }

      // disable it
      if (false && !audioPlayer.__setGraphics) {
        audioPlayer.__setGraphics = audioPlayer.setGraphics;
        audioPlayer.setGraphics = function(act) {
          audioPlayer.__setGraphics.apply(audioPlayer, arguments);
          return;
          /*if (self.watchGraphicsChange) {
            if (browser.safari) self.sendOperateTrack(audioPlayer.id, (act == 'play' || act == 'load') ? 'play' : 'pause');
            self.watchGraphicsChange = false;
          }*/
        };
      }
    }

    log('[wrapAudioMethods] wrapped DONE');
  }

  function clear() {
    log('clear()');
    _currentTrackId = null;
    _lastPlaylistSummary = null;
    _lastPlaylistId = null;
    _sid = null;
    _watchGraphicsChange = false;
  }

  /*function getBrowser() {
    return browser.safari ? 'safari' : 'chrome';
  }*/

  function executeCommand(command, plid) {
    if (command == 'afterInjection') {
      log('executeCommand: afterInjection');
      var pl = padAudioPlaylist();
      if (window.audioPlayer && pl) {
        updatePlaylist(getPlaylist(pl));
      } else {
        clearPlaylist();
      }
      return;
    }

    log('executeCommand:', command, plid);
    // var self = this;

    if (!window.audioPlayer || !padAudioPlaylist()) {
      log('[executeCommand] audioplayer or playlist not found');
      stManager.add(['audioplayer.js'], function() {
        executeAfterPadLoading(function() {
          log('[executeCommand] after execafterpadloading, window.audioPlayer:', window.audioPlayer);
          wrapAudioMethods();

          var plist = padAudioPlaylist();
          if (plist) {
            log('[executeCommand] after exec...: send updatePlaylist() with plist');
            updatePlaylist(getPlaylist(plist));
          }

          if (command == 'playpause' || command == 'next' || command == 'prev') {
            log('[executeCommand] after exec...: simple command');
            var id = getPlayFirstId();
            if (id) {
              log('[executeCommand] after exec...: found id='+id+', playAudioNew() now');
              playAudioNew(id);
            } else if (plist && plist.start) {
              log('[executeCommand] after exec...: found plist.start, playAudioNew() now');
              playAudioNew(plist.start);
            }
          } else if (startsWith(command, 'operateTrack:')) { // TODO this is new fix
            var id = parseInt(command.replace('operateTrack:'));
            log('[executeCommand] after exec...: got operateTrack, id='+id);
            if (!plist[id]) {
              log('[executeCommand] after exec...: after got operateTrack: plist[id] not found, send new pl to app');
              //self.clearPlaylist();
              updatePlaylist(getPlaylist(plist));
              if (plist.start) {
                log('[executeCommand] after exec...: got operateTrack, pl not found... ... play plist.start now');
                playAudioNew(plist.start);
              }
            } else {
              log('[executeCommand] after exec...: got operateTrack, it is found, playAudioNew() now');
              playAudioNew(id);
            }
          }
        });
      });
      return;
    }

    function evaluateCommand(command) {
      switch (command) {
        case 'next':
        case 'prev':
        case 'playpause':
          if (audioPlayer.id) {
            if (command == 'next')  next();
            else if (command == 'prev') prev();
            else if (command == 'playpause') playPause();
          } else {
            var id = getPlayFirstId();
            if (id) playId(id);
          }
          break;

        default:
          if (startsWith(command, 'operateTrack:')) {
            log('[executeCommand] got operateTrack;');
            var id = command.replace('operateTrack:', ''), pl = padAudioPlaylist();
            if (pl[id] !== undefined) {
              log('[executeCommand] got operateTrack; track is found, playAudioNew() now');
              //playAudioNew(id);
              //audioPlayer.operate(id);
              playId(id);
            } else {
              log('[executeCommand] got operateTrack; track not found, updatePlaylist with pl:', pl);
              updatePlaylist(getPlaylist(pl));
              var id = getPlayFirstId();
              if (id) {
                log('[executeCommand] got operateTrack; play id from getPlayFirstId() now');
                playId(id);
              }
            }
          }
          break;
      }
    }

    if (plid != _lastPlaylistId) {
      log('[executeCommand] plid does not match');
      var pl = padAudioPlaylist();
      if (pl) {
        updatePlaylist(getPlaylist(pl), true);
        log('[executeCommand] plid does not match, sent updatePlaylist() with pl:', pl);

        if (plid == 0)  {
          evaluateCommand(command);
        } else {
          if (['next', 'prev', 'playpause'].indexOf(command) != -1) {
            var id = audioPlayer.id || pl.start || getPlayFirstId();
            if (id) {
              playId(id);
            }
          }
        }
      }     
    } else {
      evaluateCommand(command);
    }
  }

  function setTrackId(id, _status) {
    _status = _status || (audioPlayer.player.paused() ? 'pause' : 'play');
    clearTimeout(_setTrackIdTimeout);

    var check = function() {
      if (audioPlayer.player) {
        sendOperateTrack(id, _status);
      } else {
        _setTrackIdTimeout = setTimeout(check, 200);
      }
    };
    check();
  }

  function sendOperateTrack(id, _status) {
    log('[sendOperateTrack]', id, _status);
    client.send({
      command: 'operateTrack',
      data: {
        'id': id,
        'status': _status,
        'playlistId': _lastPlaylistId
      }
    });
  }

  function setToOperateQueue(id, _status) {
    var q = _operateQueue;
    for (var i = 0; i < q.length; i++) {
      var track = q[i];
      if (track[0] == id) {
        track[1] = _status;
        return;
      }
    }
    q.push([id, _status]);
  }

  function existsInCurrentPlaylist(id) {
    return _lastPlaylistSummary && _lastPlaylistSummary.indexOf(id) != -1;
  }

  function processOperateQueue(pl) {
    log('[processOperateQueue]');
    var q = _operateQueue;
    while (q.length) {
      var track = q.shift();
      log('[processOperateQueue] track:', track[0]);
      if (pl[track[0]] !== undefined) {
        log('[processOperateQueue] track', track[0], 'found, send it now');
        sendOperateTrack(track[0], track[1]);
      }
    }
  }

  function clearOperateQueue() {
    _operateQueue = [];
  }

  function printPlaylist() {
    var pl = padAudioPlaylist();
    if (pl) {
      for (var k in pl) {
        log(pl[k][5] + ' - ' + pl[k][6]);
      }
    }
  }

  function getPlaylist(_pl) {
    _pl = _pl || padAudioPlaylist();
    var pl = null;
    if (_pl) {
      var start = _pl.start, pl = [];
      var nextId = start;
      do {
        if (_pl[nextId]) {
          _pl[nextId]._vkpcId = nextId;
          pl.push(_pl[nextId]);
          nextId = _pl[nextId]._next;
        }
      } while (nextId != '' && nextId !== undefined && nextId != start);
    }
    return pl;
  }

  // force=true is used when plids not match
  function updatePlaylist(pl, force) {
    var tracks = [], summary = [], title;
    if (pl) {
      for (var k = 0; k < pl.length; k++) {
        tracks.push({
          id: pl[k]._vkpcId,
          artist: decodeEntities(pl[k][5]),
          title: decodeEntities(pl[k][6]),
          duration: pl[k][4]
        });
        summary.push(pl[k]._vkpcId);
      }
      
      summary = summary.join(';');

      log("updatePlaylist: _lastPlaylistSummary:", _lastPlaylistSummary, 'summary:', summary);
      if (force || _lastPlaylistSummary === null || _lastPlaylistSummary !== summary) {
        log('[updatePlaylist] last summary not matched;', _lastPlaylistSummary, summary);
        var activeId = '', activeStatus = '';
        var vkpl = padAudioPlaylist();
        var plTitle = (window.audioPlaylist && window.audioPlaylist.htitle) || vkpl.htitle;
        if (audioPlayer.id && vkpl[audioPlayer.id] !== undefined) {
          activeId = audioPlayer.id;
          _watchGraphicsChange = true;

          activeStatus = getPlayerStatus(true) ? 'play' : 'pause';
          _watchGraphicsChange = true;
        }

        _lastPlaylistSummary = summary;
        _lastPlaylistId = random(100000, 1000000);

        log("[updatePlaylist] send pl with id="+_lastPlaylistId+', activeId='+activeId+', activeStatus='+activeStatus+' to app');
        try {
          client.send({
            command: 'updatePlaylist',
            data: {
              tracks: tracks,
              title: parsePlaylistTitle(plTitle) || "",
              id: _lastPlaylistId,
              active: { 'id': activeId, 'status': activeStatus },
              // browser: getBrowser()
            }
          });
        } catch(e) {
          log('[updatePlaylist] exception:', e, e.stack);
        }

        processOperateQueue(pl);
      }
    }
  }

  function clearPlaylist(no_send, called_from) {
    called_from = called_from || "";
    log('[clearPlaylist] (this may be called from: '+called_from+')');
    _lastPlaylistSummary = null;
    _lastPlaylistId = 0;
    if (!no_send) {
      client.send({command: 'clearPlaylist', data: {}});
    }
  }

  function checkPlaylist() {
    var pl = padAudioPlaylist();
    if (!pl) {
      clearPlaylist(true, 'checkPlaylist');
    }
  }

  function parsePlaylistTitle(str) {
    str = str || "";
    str = trim(str);
    if (str == '') return str;

    var starts = {
      0: 'Сейчас играет — ', // ru
      100: '\u041d\u044b\u043d\u0447\u0435 \u0438\u0433\u0440\u0430\u0435\u0442\u044a\u2014 ', // re
      3: 'Now playing — ', // en
      1: 'Зараз звучить — ', // ua
      777: 'Проигрывается пластинка «' // su
    };
    var ends = {
      0: ' \\| [0-9]+ аудиоза[^\\s]+$',
      3: ' \\| [0-9]+ audio [^\\s]+$',
      1: ' \\| [0-9]+ аудіоза[^\\s]+$',
      100: ' \\| [0-9]+ композ[^\\s]+$',
      777: ' \\| [0-9]+ грамза[^\\s]+»$'
    };

    if (window.vk && vk.lang !== undefined) {
      if (starts[vk.lang] !== undefined && startsWith(str, starts[vk.lang])) {
        str = str.substring(starts[vk.lang].length);
      }

      if (ends[vk.lang] !== undefined) {
        var regex = new RegExp(ends[vk.lang], 'i');
        if (str.match(regex)) str = str.replace(regex, '');
      }
    }

    return stripTags(trim(str));
  }

  function afterInjection() {
    log("after injection");
    var pl = getPlaylist();
    if (pl) updatePlaylist(pl);
  }

  function next() {
    audioPlayer.nextTrack(true, !window.audioPlaylist)
    /*if (audioPlayer.controls && audioPlayer.controls.pd && audioPlayer.controls.pd.next) {
      audioPlayer.controls.pd.next.click();
    } else {
      audioPlayer.nextTrack(true, !window.audioPlaylist)
    }*/
  }

  function prev() {
    audioPlayer.prevTrack(true, !window.audioPlaylist);
    /*if (audioPlayer.controls && audioPlayer.controls.pd && audioPlayer.controls.pd.prev) {
      audioPlayer.controls.pd.prev.click(); 
    } else {
      audioPlayer.prevTrack(true, !window.audioPlaylist);
    }*/
  }

  function getPlayFirstId() {
    var id = currentAudioId() || ls.get('audio_id') || (window.audioPlaylist && audioPlaylist.start);
    return id || null;
  }
 
  function playFirst() {
    var id = getPlayFirstId();
    
    if (id) playId(id);
    else {
      var plist = padAudioPlaylist();
      if (plist && plist.start) {
        playId(plist.start);
      } else {
        executeAfterPadLoading(function() {
          var plist = padAudioPlaylist();
          if (plist && plist.start) {
            playId(plist.start);
          }
        });
      }
    }
  }

  function executeAfterPadLoading(f) {
    Pads.show('mus');
    window.onPlaylistLoaded = function() {
      if (f) {
        try {
          f();
        } catch(e) {}
      }
      setTimeout(function() {
        Pads.show('mus');
      }, 10);
    }
  }

  function getPlayerStatus(justStarted) {
    if (!audioPlayer.player) return false;
    try {
      var pl = audioPlayer.player;
      if (pl && pl.music && pl.music.buffered && !pl.music.buffered.length && justStarted) return true;
    } catch (e) {
      return true;
    }

    return audioPlayer.player && !audioPlayer.player.paused();
  }

  function pauseForSafari() {
    if (window.audioPlayer && audioPlayer.player) audioPlayer.pauseTrack();
  }

  function playPause() {
    if (window.audioPlayer && audioPlayer.player) {
      if (audioPlayer.player.paused()) {
        audioPlayer.playTrack(); 
      } else {
        audioPlayer.pauseTrack();
      }
    }
  }

  function operateTrack(id) {
    if (id == audioPlayer.id) {
      playPause();
    } else {
      audioPlayer.operate(id);
    }
  }

  function playId(id) {
    if (window.audioPlayer) audioPlayer.operate(id);
    else playAudioNew(id);
  }

  function getLastInstanceId() {
    var id = null, pp = ls.get('pad_playlist');
    if (pp && pp.source) id = pp.source;
    //return [id, ls.get('vkpc_lastid')];
    return id;
  }

  this.executeCommand = executeCommand;

  this.getParams = function() {
    checkPlaylist();
    var havePlayer = window.audioPlayer !== undefined;
    var havePlaylist = havePlayer && (window.padAudioPlaylist && !!padAudioPlaylist());
    
    return [
      /* 1:havePlayer */    intval(havePlayer),
      /* 2:havePlaylist */  intval(havePlaylist),
      /* 3:isPlaying */     intval(window.audioPlayer && window.audioPlayer.player && !window.audioPlayer.player.paused()),
      /* 4:tabId */         window.curNotifier && curNotifier.instance_id,
      /* 5:trackId */       window.audioPlayer && audioPlayer.id,
      /* 6:tabPlaylistId */ intval(_lastPlaylistId || 0),
      /* 7:lsSourceId */    getLastInstanceId()
    ];
  };

  this.init = function(sid) {
    if (_checkPlaylistTimer === null) {
      _checkPlaylistTimer = setInterval(function() {
        if ((_lastPlaylistId || _lastPlaylistSummary) && !padAudioPlaylist()) {
          clearPlaylist(true, 'timer'); // TODO func
        }
      }, 1000);
    }

    if (!window.__wrappedByVKPC && window.audioPlayer && window.ls && window.stManager) {
      if (!stManager.__done) {
        stManager.__done = stManager.done;
        stManager.done = function(fn) {
          if (fn == 'audioplayer.js') {
            wrapAudioMethods(); // TODO func
          }
          stManager.__done.apply(stManager, arguments);
        };
      }

      wrapAudioMethods();

      if (!ls.__set) {
        ls.__set = ls.set;
        ls.set = function(k, v) {
          ls.__set.apply(ls, arguments);
          if (k == 'pad_playlist') {
            log('pad_playlist updated:', v);
            updatePlaylist(getPlaylist(v)); // TODO func
          }
        };
      }
      if (!ls.__remove) {
        ls.__remove = ls.remove;
        ls.remove = function(k, v) {
          ls.__remove.apply(ls, arguments);
          if (k == 'pad_playlist') {
            log('pad_playlist removed from ls');
            //self.clearPlaylist(true, 'ls.remove');
            // self.clearPlaylist();
          }
        };
      }

      window.__wrappedByVKPC = true;
    }

    if (sid === _sid) {
      return;
    }
    if (_sid !== null) {
      clear(); // TODO
    }
    _sid = sid;

    log('(re)inited OK');
  };

  this.getSID = function() {
    return _sid;
  };

  this.getLastInstanceId = getLastInstanceId;
  this.clearPlaylist = clearPlaylist;
}; // window.VKPC = ...

} // if (!window.VKPC) ...

if (!window.DOMContentLoaded) {
  window.console && console.log && console.log("[VKPC] !window.DOMContentLoaded, exising");
  return;
}

window.DOMContentLoaded(function() {
  VKPC.init(vkpc_sid);
});

return VKPC.getParams();

})({sid});
