Components.utils.import("chrome://vkpc/content/module.jsm");

VKPC.startup();

VKPC.addWindow(window);
window.addEventListener('close', function() {
  VKPC.removeWindow(window);
});
