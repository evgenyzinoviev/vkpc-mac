Components.utils.import("resource://gre/modules/Services.jsm");

try {
  var console = (Components.utils.import("resource://gre/modules/devtools/Console.jsm", {})).console;
} catch (e) {}

function log() {
  var msgs = [], i, tmp;
  for (i = 0; i < arguments.length; i++) {
    if (arguments[i] instanceof Error) tmp = [arguments[i], arguments[i].stack];
    else tmp = arguments[i];
    msgs.push(tmp);
  }

  msgs.unshift('[VKPC bootstrap.js]');
  try {
    console.log.apply(console, msgs);
  } catch(e) {}
}

function startup(data, reason) {
  Components.utils.import("chrome://vkpc/content/module.jsm");
  VKPC.startup();

  var windows = Services.wm.getEnumerator("navigator:browser");
  while (windows.hasMoreElements()) {
    var win = windows.getNext().QueryInterface(Components.interfaces.nsIDOMWindow);
    VKPC.addWindow(win, win.document && win.document.readyState == 'complete');
  }

  Services.wm.addListener(WindowListener);
}
function shutdown(data, reason) {
  if (reason == APP_SHUTDOWN)
    return;

  Services.wm.removeListener(WindowListener);

  VKPC.shutdown();

  if (reason == ADDON_DISABLE) {
    Services.obs.notifyObservers(null, "startupcache-invalidate", null);
    Services.obs.notifyObservers(null, "chrome-flush-caches", null);
  }
}
function install(data, reason) {}
function uninstall(data, reason) {}

function forEachOpenWindow() {
  var windows = Services.wm.getEnumerator("navigator:browser");
  while (windows.hasMoreElements()) {
    VKPC.addWindow(windows.getNext().QueryInterface(Components.interfaces.nsIDOMWindow));
  }
}

var WindowListener = {
  onOpenWindow: function(xulWindow) {
    var window = xulWindow.QueryInterface(Components.interfaces.nsIInterfaceRequestor)
                           .getInterface(Components.interfaces.nsIDOMWindow);
    window.addEventListener("load", function onWindowLoad() {
      window.removeEventListener("load", onWindowLoad);

      if (window.document.documentElement.getAttribute("windowtype") == "navigator:browser") {
        VKPC.addWindow(window, true);
      }
    });
  },
  onCloseWindow: function(xulWindow) {
    VKPC.removeWindow(xulWindow.QueryInterface(Components.interfaces.nsIInterfaceRequestor)
                           .getInterface(Components.interfaces.nsIDOMWindow));
  },
  onWindowTitleChange: function(xulWindow, newTitle) { }
};
