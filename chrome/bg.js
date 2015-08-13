var wsc, injectInterval;

function init() {
  // receive messages from webpage
  chrome.runtime.onMessageExternal.addListener(function(msg, sender, sendResponse) {
    if (msg.cmd == "injection_result") {
      var obj = Injections.get(msg.id);
      if (obj) {
        obj.addResponse(sender.tab.id, msg.data);
      }
    }
    if (msg.cmd == "to_app") {
      // log('to_app received', msg.data);
      wsc.send(msg.data);
    }
  });

  // connect to the app
  wsc = new WSClient("wss://vkpc-local.ch1p.com:56130", "signaling-protocol", {
    onopen: function() {
      Controller.clear();
      this.send({command: 'setBrowser'});
    },
    onmessage: function(cmd) {
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

      // executeCommand(msg);
    },
    onerror: function() {
      this.reconnect();
    },
    onclose: function() {
      this.reconnect();
    }
  });
  wsc.connect();

  injectInterval = setInterval(function() {
    inject('afterInjection');
  }, 2000);
}

function sendClear() {
  wsc.send({command: 'clearPlaylist', data: null});
}

function inject(command, callback) {
  var injId = Injections.getNextId();
  var data = {
    extid: getExtensionId(),
    injid: injId,
    sid: Controller.sid,
    command: command
  };
  var code_inj = "var el = document.createElement('script');" +
    "el.src = chrome.extension.getURL('vkpc.js');" +
    "document.body.appendChild(el);" +
    "var el1 = document.createElement('script');" +
    "el1.textContent = 'window.__vkpc_data = "+JSON.stringify(data)+"';" +
    "document.body.appendChild(el1)";

  var okTab_nowPlaying, okTab_playlistFound, okTab_lsSource, okTab_recentlyPlayed, okTab_havePlaylist,
      activeTab, lastTab, outdatedTabs = [], tabsWithPlayingMusic = []/*, tabPlaylistIds = {}*/;
  var lsSourceId, appPlaylistFound = false;

  var injResponses, injResults;

  function getCode(code) {
    return "var el = document.createElement('script');" + 
      "el.textContent = '"+code.replace(/'/g, "\\'")+"';" +
      "document.body.appendChild(el)";
  }
  function onDone(step) {
    var results = injResponses.results;
    var execCommand = getCode("VKPC.executeCommand('"+command+"', "+Controller.playlistId+")");

    if (command == 'afterInjection') {
      //log('[afterInjection onDone] results.length='+results.length);

      for (var i = 0; i < results.length; i++) {
        var data = results[i].data, tab = results[i].tab;

        // tabPlaylistIds[tab] = data.playlistId;
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
          chrome.tabs.executeScript(okTab, {code: execCommand});
        } else if (!appPlaylistFound) {
          sendClear();
        }
      }

      for (var i = 0; i < outdatedTabs.length; i++) {
        chrome.tabs.executeScript(outdatedTabs[i], {code: getCode('VKPC.clearPlaylist(true, "as")')});
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
      //log('check[] =', check);
      for (var i = 0; i < check.length; i++) {
        if (check[i] !== undefined) {
          chrome.tabs.executeScript(check[i], {code: execCommand});
          break;
        }
      }
    }

    injResponses.unregister();
    callback && callback();
  }

  getVKTabs(function(tabs) {
    if (!tabs.length) {
      sendClear();
      return;
    }

    injResponses = new InjectionResponses(injId, tabs.length, onDone);
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].active) {
        activeTab = tabs[i].id;
      }
      chrome.tabs.executeScript(tabs[i].id, {
        code: code_inj
      });
    }
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

DOMContentLoaded(init);
