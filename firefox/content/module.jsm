var EXPORTED_SYMBOLS = ['VKPC'];

try {
  var console = (Components.utils.import("resource://gre/modules/devtools/Console.jsm", {})).console;
} catch (e) {}

var browser = {
  id: 1,
  chrome: false,
  safari: false,
  yandex: false,
  firefox: true,
  opera: false
};

var started = false;

function createTimeout(callback, interval) {
  return new function() {
    var timer = Components.classes["@mozilla.org/timer;1"].createInstance(Components.interfaces.nsITimer);
    timer.initWithCallback({
      notify: function() {
        callback();
      }
    }, interval, Components.interfaces.nsITimer.TYPE_ONE_SHOT);

    this.cancel = function() {
      timer.cancel();
      timer = null;
    };
  }
}
function createInterval(callback, interval) {
  return new function() {
    var timer = Components.classes["@mozilla.org/timer;1"].createInstance(Components.interfaces.nsITimer);
    timer.initWithCallback({
      notify: function() {
        callback();
      }
    }, interval, Components.interfaces.nsITimer.TYPE_REPEATING_SLACK);

    this.cancel = function() {
      timer.cancel();
      timer = null;
    };
  }
}
function log() {
  return; // comment for debugging

  var msgs = [], i, tmp;
  for (i = 0; i < arguments.length; i++) {
    if (arguments[i] instanceof Error) tmp = [arguments[i], arguments[i].stack];
    else tmp = arguments[i];
    msgs.push(tmp);
  }

  msgs.unshift('[VKPC module.jsm]');
  try {
    console.log.apply(console, msgs);
  } catch(e) {}
}
function extend(dest, source) {
  for (var i in source) {
    dest[i] = source[i];
  }
  return dest;
}
function createCData(data) {
  var parser = Components.classes["@mozilla.org/xmlextras/domparser;1"]
    .createInstance(Components.interfaces.nsIDOMParser);
  var doc = parser.parseFromString('<xml></xml>', "application/xml");
  var cdata = doc.createCDATASection(data);
  doc.getElementsByTagName('xml')[0].appendChild(cdata);
  return cdata;
}
function remove(element) {
  element.parentNode.removeChild(element);
}

function InjectionResponses(id, count, callback) {
  this.id = id;
  this.results = [];
  this.lsSource = null;
  this.maxCount = count;
  this.callback = callback || function() {};

  Injections.register(this.id, this);
}
extend(InjectionResponses.prototype, {
  addResponse: function(id, response) {
    this.results.push({tab: id, data: response});
    if (!this.lsSource && response && response.lastInstanceId) this.lsSource = response.lastInstanceId;
    if (this.results.length == this.maxCount) {
      this.callback();
    }
  },
  unregister: function() {
    Injections.unregister(this.id);
  }
});

var Injections = {
  id: 0,
  objs: {},
  getNextId: function() {
    if (this.id == Number.MAX_VALUE) {
      this.id = -1;
    }
    return ++this.id;
  },
  get: function(id) {
    return this.objs[id] || false;
  },
  register: function(id, obj) {
    this.objs[id] = obj;
  },
  unregister: function(id) {
    if (this.objs[id] !== undefined) delete this.objs[id];
  }
};

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
  connect: function(callback) {
    this.state = WSC_STATE_NONE;
    var self = this;

    this._waitForWebSocketAvailable(function(_websocket) {
      log('_waitForWebSocketAvailable DONE');
      self._ws = new _websocket(self.address, self.protocol);

      if (!self._ws) {
        log('websockets are not supported');
        return;
      }

      self._ws.onopen = function() {
        self.state = WSC_STATE_OK;
        self._setTimers();
        self._onopen && self._onopen.apply(self);
      };
      self._ws.onerror = function() {
        self._unsetTimers();
        if (self.state != WSC_STATE_ERR) {
          self.state = WSC_STATE_ERR;
        }
        self._onerror && self._onerror.apply(self);
      };
      self._ws.onclose = function() {
        self._unsetTimers();
        if (self.state != WSC_STATE_ERR) {
          self.state = WSC_STATE_ERR;
        }
        self._onclose && self._onclose.apply(self);
      };
      self._ws.onmessage = function(e) {
        self._onmessage && self._onmessage.apply(self, [e.data]);
      };

      callback && callback();
    }, 200);
  },
  close: function() {
    this._unsetTimers();
    if (this._ws) {
      this.state = WSC_STATE_CLOSED;
      this._ws.close();
    }
  },
  reconnect: function() {
    var self = this;
    if (this.state == WSC_STATE_OK) {
      try {
        log('[WSClient reconnect] state = '+this.state+', why reconnect?');
      } catch (e) {}
      return;
    }
    if (this._reconnectTimer) {
      this._reconnectTimer.cancel();
    }
    this._reconnectTimer = createTimeout(function() {
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
    this._unsetTimers();
    this._pingTimer = createInterval(function() {
      try {
        self._ws.send("PING");
      } catch (e) {
        log('[WSClient _pingTimer]', e);
      }
    }, 30000);
  },
  _unsetTimers: function() {
    if (this._pingTimer)
      this._pingTimer.cancel();
  },
  _waitForConnection: function(callback, interval) {
    if (this._ws.readyState === 1) {
      callback();
    } else {
      var self = this;
      var timer = createTimeout(function() {
        timer.cancel();
        self._waitForConnection(callback, interval);
      }, interval);
    }
  },
  _waitForWebSocketAvailable: function(callback, interval) {
    var win, self = this;
    try {
      win = Components.classes["@mozilla.org/appshell/appShellService;1"].
                     getService(Components.interfaces.nsIAppShellService).
                     hiddenDOMWindow;
    } catch (e) {
      var timer = createTimeout(function() {
        timer.cancel();
        self._waitForWebSocketAvailable(callback, interval);
      }, interval);
    } finally {
      if (win) {
        callback(win.WebSocket || win.MozWebSocket);
      }
    }
  }
});

var Documents = {
  list: [],
  add: function(doc) {
    this.cleanup();
    this.list.push(doc);
  },
  cleanup: function() {
    this.list = this.list.filter(function(t) {
      return Object.prototype.toString.call(t) != '[object DeadObject]';
    });
  },
  send: function(json) {
    var self = this;
    this.cleanup();

    this.list.forEach(function(doc) {
      self.sendToDoc(doc, json);
    });
  },
  sendToDoc: function(doc, json) {
    var cdata = createCData(JSON.stringify(json));
    doc.getElementById('utils').appendChild(cdata);

    var evt = doc.createEvent("Events");
    evt.initEvent("VKPCBgMessage", true, false);
    cdata.dispatchEvent(evt);    
  },
  getCount: function() {
    this.cleanup();
    return this.list.length;
  }
};

function sendClear() {
  wsc.send({command: 'clearPlaylist', data: null});
}

function prepareWindow(win) {
  function onPageLoaded(e) {
    var doc = e.originalTarget, loc = doc.location;
    if (!loc.href.match(/^https?:\/\/vk.com\/.*$/)) return;

    doc.addEventListener("VKPCInjectedMessage", function(e) {
      var target = e.target, json = JSON.parse(target.data || "{}"), doc = target.ownerDocument;
      receiveMessage(json, doc, target);
    }, false);

    var loader = Components.classes["@mozilla.org/moz/jssubscript-loader;1"]
                           .getService(Components.interfaces.mozIJSSubScriptLoader);
    loader.loadSubScript("chrome://vkpc/content/vkpc.js", doc); 
  }

  var appcontent = win.document.getElementById("appcontent");
  if (appcontent) {
    appcontent.addEventListener("DOMContentLoaded", onPageLoaded, true);
  }
}

// receive message from tab
function receiveMessage(json, doc, target) {
  switch (json.cmd) {
  case "register":
    Documents.add(doc);
    break;

  case "afterInjection":
    var id = json.id;
    var obj = Injections.get(id);
    if (obj) {
      obj.addResponse(doc, json.data);
    }
    break;

  case "to_app":
    wsc.send(json.data);
    break;
  }

  try {
    remove(target);
  } catch (e) {}
}

// send message to tabs
function sendMessage(data, tab) {
  if (tab) {
    Documents.sendToDoc(tab, data);
  } else {
    Documents.send(data);
  }
}

function inject(command/*, callback*/) {
  //log('inject', command);
  var injId = Injections.getNextId();
  var data = {
    sid: Controller.sid,
    command: command
  };

  var okTab_nowPlaying, okTab_playlistFound, okTab_lsSource, okTab_recentlyPlayed, okTab_havePlaylist,
      activeTab, lastTab, outdatedTabs = [], tabsWithPlayingMusic = [];
  var lsSourceId, appPlaylistFound = false;

  var injResponses, injResults;

  function onDone(step) {
    var results = injResponses.results;
    // var execCommand = getCode("VKPC.executeCommand('"+command+"', "+Controller.playlistId+")");
    var vkpcCommand = {cmd: 'vkpc', command: command, playlistId: Controller.playlistId};

    if (command == 'afterInjection') {
      // log('[afterInjection onDone] results.length='+results.length);

      for (var i = 0; i < results.length; i++) {
        var data = results[i].data, tab = results[i].tab;

        if (data.playlistId != 0 && data.playlistId == Controller.playlistId) {
          appPlaylistFound = true;
        }
        if (data.havePlaylist && data.playlistId != 0 && data.playlistId != Controller.playlistId) {
          outdatedTabs.push(tab);
        }
        if (data.havePlaylist) {
          okTab_havePlaylist = tab;
        }
        if (data.isPlaying) {
          okTab_nowPlaying = tab;
        }
      }

      if (!appPlaylistFound) {
        var okTab = okTab_nowPlaying || okTab_havePlaylist;
        if (okTab !== undefined) {
          sendMessage(vkpcCommand, okTab);
        } else {
          sendClear();
        }
      }

      for (var i = 0; i < outdatedTabs.length; i++) {
        sendMessage({cmd: 'vkpc', command: 'clearPlaylist'}, outdatedTabs[i]);
      }
    } else {
      for (var i = 0; i < results.length; i++) {
        var data = results[i].data;
        if (!lsSourceId && data.lsSourceId) {
          lsSourceId = data.lsSourceId;
          break;
        }
      }

      for (var i = 0; i < results.length; i++) {
        var data = results[i].data, tab = results[i].tab;

        if (data.playlistId == Controller.playlistId) {
          okTab_playlistFound = tab;
        }
        if (data.havePlayer && (data.isPlaying || typeof data.trackId == 'string')) {
          okTab_recentlyPlayed = tab;
        }
        if (data.isPlaying) {
          okTab_nowPlaying = tab;
        }
        if (lsSourceId == data.tabId) {
          okTab_lsSource = tab;
        }

        lastTab = tab;
      }

      var check = [okTab_nowPlaying, okTab_lsSource, okTab_recentlyPlayed, okTab_recentlyPlayed, okTab_havePlaylist, activeTab, lastTab];
      for (var i = 0; i < check.length; i++) {
        if (check[i] !== undefined) {
          sendMessage(vkpcCommand, check[i]);
          // chrome.tabs.executeScript(check[i], {code: execCommand});
          break;
        }
      }
    }

    injResponses.unregister();
  }

  var count = Documents.getCount();
  //log('vk tabs count: ' + count);

  if (!count) {
    log('vk tabs not found');
    sendClear();
    return;
  }

  injResponses = new InjectionResponses(injId, Documents.getCount(), onDone);
  sendMessage({
    cmd: "afterInjection",
    id: injId,
    data: data
  });
};

var Controller = {
  sid: 0,
  playlistId: 0,
  clear: function() {
    this.sid = 0;
    this.playlistId = 0;
  }
};

var VKPC = new function() {
  var timer;
  log('VKPC()');
  
  var windows = [];
  this.addWindow = function(win, notWait) {
    if (windows.indexOf(win) == -1) {
      log('window added', win);
      windows.push(win);

      if (!notWait) {
        win.addEventListener('load', function load(e) {
          win.removeEventListener('load', load, false);
          prepareWindow(win);
        }, false);
      } else {
        prepareWindow(win);
      }
    }
  };
  this.removeWindow = function(win) {
    var index;
    if ((index = windows.indexOf(win)) != -1) {
      log('window removed', win);
      windows.splice(index, 1);
    }
  };

  var self = this;
  this.startup = function() {
    if (started) {
      log('already started, ignoring');
      return;
    }

    wsc = new WSClient("wss://vkpc-local.ch1p.com:56130", "signaling-protocol", {
      onopen: function() {
        Controller.clear();
        this.send({command: 'setBrowser'});

        if (timer) {
          timer.cancel();
        }
        timer = createInterval(function() {
          inject('afterInjection');
        }, 2000);
      },
      onmessage: function(cmd) {
        log('[wsc onmessage] cmd:', cmd);
        
        var json = JSON.parse(cmd);
        switch (json.command) {
          case 'set_sid':
            Controller.sid = json.data;
            break;

          case 'set_playlist_id':
            Controller.playlistId = json.data;
            break;

          case 'vkpc':
            inject(json.data);
            break;
        }
      },
      onerror: function() {
        if (timer) {
          timer.cancel();
        }
        this.reconnect();
      },
      onclose: function() {
        if (timer) {
          timer.cancel();
        }
        if (started) {
          this.reconnect();
        }
      }
    });
    wsc.connect();

    self.wsc = wsc;
    started = true;
  };
  this.shutdown = function() {
    if (!started) {
      return;
    }

    started = false;

    if (wsc) {
      wsc.close();
      wsc = undefined;
    }
    if (timer) {
      timer.cancel();
      timer = undefined;
    }
  };

  log('init finish');
};
