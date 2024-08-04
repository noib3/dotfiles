// See [1] for a list of valid modifiers.

SessionStore.promiseInitialized.then(() => {
  // Close the current tab with Super+W.
  let key = document.getElementById("key_close");
  key.removeAttribute("key");
  key.removeAttribute("modifiers");
  key.setAttribute("modifiers", "meta");
  key.setAttribute("key", "W");
});

// [1]: https://web.archive.org/web/20191007211804/https://developer.mozilla.org/en-US/docs/Archive/Mozilla/XUL/Tutorial/Keyboard_Shortcuts
