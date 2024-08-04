// See [1] for a list of valid modifiers.

SessionStore.promiseInitialized.then(() => {
  // TODO: Copy w/ Super+c.
  let copy = document.getElementById("key_copy");
  copy.setAttribute("modifiers", "meta");
  copy.setAttribute("key", "C");

  // TODO: Paste w/ Super+v.
  let paste = document.getElementById("key_paste");
  paste.setAttribute("modifiers", "meta");
  paste.setAttribute("key", "V");

  // TODO: Cut w/ Super+x.
  let cut = document.getElementById("key_cut");
  cut.setAttribute("modifiers", "meta");
  cut.setAttribute("key", "X");

  // TODO: Delete the previous word w/ Alt+delete.
  let deleteWord = document.getElementById("key_delete");
  deleteWord.setAttribute("modifiers", "alt");
  deleteWord.setAttribute("key", "VK_BACK");

  // Close the current tab w/ Super+w.
  let closeTab = document.getElementById("key_close");
  closeTab.setAttribute("modifiers", "meta");
  closeTab.setAttribute("key", "W");

  // Focus the URL bar w/ Super+l.
  let focusUrl = document.getElementById("focusURLBar");
  focusUrl.setAttribute("modifiers", "meta");
  focusUrl.setAttribute("key", "L");

  // Open a new tab w/ Super+t.
  let openTab = document.getElementById("key_newNavigatorTab");
  openTab.setAttribute("modifiers", "meta");
  openTab.setAttribute("key", "T");

  // Open a new window w/ Super+n.
  let openWindow = document.getElementById("key_newNavigator");
  openWindow.setAttribute("modifiers", "meta");
  openWindow.setAttribute("key", "N");

  // Open a new private window w/ Super+Shift+n.
  let openPrivateWindow = document.getElementById("key_privatebrowsing");
  openPrivateWindow.setAttribute("modifiers", "meta,shift");
  openPrivateWindow.setAttribute("key", "N");

  // Go back w/ Super+left.
  let goBack = document.getElementById("goBackKb");
  goBack.setAttribute("modifiers", "meta");
  goBack.setAttribute("keycode", "VK_LEFT");

  // Go forward w/ Super+right.
  let goForward = document.getElementById("goForwardKb");
  goForward.setAttribute("modifiers", "meta");
  goForward.setAttribute("keycode", "VK_RIGHT");

  // Scroll to top w/ Super+up.
  // let scrollToTop = document.getElementById("goForwardKb");
  // scrollToTop.setAttribute("modifiers", "meta");
  // scrollToTop.setAttribute("keycode", "VK_UP");

  // Scroll to bottom w/ Super+up.
  // let scrollToBottom = document.getElementById("goForwardKb");
  // scrollToBottom.setAttribute("modifiers", "meta");
  // scrollToBottom.setAttribute("keycode", "VK_DOWN");

  // Focus the n-th tab w/ Super+n.
  for (let i = 1; i <= 8; i++) {
    let focusTab = document.getElementById(`key_selectTab${i}`);
    focusTab.setAttribute("modifiers", "meta");
    focusTab.setAttribute("key", `${i}`);
  }
});

// [1]: https://web.archive.org/web/20191007211804/https://developer.mozilla.org/en-US/docs/Archive/Mozilla/XUL/Tutorial/Keyboard_Shortcuts
