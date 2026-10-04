// Tokopedia's English interface still contains Indonesian text, but its HTML
// declares English and disables translation for the entire document.
(() => {
  const start = () => {
    const root = document.documentElement;
    if (!root) return false;

    const enableTranslation = () => {
      if (root.getAttribute("translate") !== "yes") {
        root.setAttribute("translate", "yes");
      }
      if (root.getAttribute("lang") !== "id") {
        root.setAttribute("lang", "id");
      }
    };

    enableTranslation();
    // Keep the fix when Tokopedia rewrites these attributes during navigation.
    new MutationObserver(enableTranslation).observe(root, {
      attributes: true,
      attributeFilter: ["lang", "translate"],
    });
    return true;
  };

  if (!start()) {
    const observer = new MutationObserver(() => {
      if (start()) observer.disconnect();
    });
    observer.observe(document, { childList: true });
  }
})();
