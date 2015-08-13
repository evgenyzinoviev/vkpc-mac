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

function getExtensionId() {
  return chrome.i18n.getMessage("@@extension_id");
}

function getVKTabs(callback) {
  var vkTabs = [];
  chrome.tabs.query({}, function(tabs) {
    for (var i = 0; i < tabs.length; i++) {
      var tab = tabs[i];
      if (tab.url.match(new RegExp('https?://vk.com/.*', 'gi'))) {
        vkTabs.push(tab);
      }
    }
    callback(vkTabs);
  });
}

function extend(dest, source) {
  for (var i in source) {
    dest[i] = source[i];
  }
  return dest;
}
function log() {
  var msgs = [], i, tmp;
  for (i = 0; i < arguments.length; i++) {
    if (arguments[i] instanceof Error) tmp = [arguments[i], arguments[i].stack];
    else tmp = arguments[i];
    msgs.push(tmp);
  }

  try {
    console.log.apply(console, msgs);
  } catch(e) {}
}
function intval(value) {
  if (value === true) return 1;
  return parseInt(value) || 0;
}
function str(v) {
  var str;
  if (v && v.toString)
    str = v.toString();
  else 
    str = v + '';
  if (str == '[object Object]') {
    str = JSON.stringify(v);
  }
  return str;
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
        eventsAdded = true;
      }
    }
  }
})(window, document);

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
