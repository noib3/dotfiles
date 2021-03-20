{ font, colors }:
let
  userChrome = ''
    * {
      font-family: "${font.family}";
      font-size: ${font.size} !important;
    }

    :root {
      --color-unfocused-tabs-bg: ${colors.tabs.unfocused.bg};
      --color-unfocused-tabs-fg: ${colors.tabs.unfocused.fg};

      --color-focused-tabs-bg: ${colors.tabs.focused.bg};
      --color-focused-tabs-fg: ${colors.tabs.focused.fg};

      --color-urlbar-bg: ${colors.urlbar.bg};
      --color-urlbar-fg: ${colors.urlbar.fg};
      --color-urlbar-popup-url: ${colors.urlbar.url.fg};
      --color-urlbar-separator: ${colors.urlbar.separator};

      --color-urlbar-selected-bg: ${colors.urlbar.selected.bg};
      --color-urlbar-selected-fg: ${colors.urlbar.selected.fg};
      --color-urlbar-selected-popup_url: ${colors.urlbar.selected.fg};

      --color-sidebar-bg: ${colors.sidebar.bg};
      --color-sidebar-fg: ${colors.sidebar.fg};
    }
  ''
  + builtins.readFile ./colors.css
  + builtins.readFile ./tab-bar/debloat-tab-bar.css
  + builtins.readFile ./tab-bar/tabs-layout.css
  + builtins.readFile ./tab-bar/tabs-fill-available-width.css
  + builtins.readFile ./tab-bar/numbered-tabs.css
  + builtins.readFile ./tab-bar/tab-close-button-always-on-hover.css
  + builtins.readFile ./tab-bar/hide-tabs-with-one-tab.css
  + builtins.readFile ./nav-bar/debloat-nav-bar.css
  + builtins.readFile ./nav-bar/nav-bar-layout.css
  + builtins.readFile ./nav-bar/nav-bar-on-focus.css
  + builtins.readFile ./url-bar/debloat-url-bar.css
  + builtins.readFile ./url-bar/url-bar-layout.css
  + builtins.readFile ./url-bar/remove-megabar.css
  + builtins.readFile ./side-bar/debloat-side-bar.css
  + builtins.readFile ./side-bar/side-bar-layout.css
  + ''
    #PersonalToolbar {
      display: none !important;
    }
  '';

  userContent = ''
    @-moz-document url-prefix(about:blank) {
      * {
        background-color: ${colors.about-blank.bg} !important;
      }
    }
  '';
in
{
  extensions = with (import ./extensions.nix); [
    bitwarden
    hide-scrollbars
    tridactyl-no-new-tab
  ];

  profiles = {
    home = {
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "apz.allow_zooming" = true;
        "browser.aboutConfig.showWarning" = false;
        "browser.tabs.warnOnClose" = false;
        "browser.newtabpage.pinned" = "";
        "browser.startup.homepage" = "https://google.com";
        "browser.tabs.loadInBackground" = false;
        "browser.urlbar.update2" = false;
        "browser.urlbar.shortcuts.bookmarks" = false;
        "browser.urlbar.shortcuts.tabs" = false;
        "browser.urlbar.shortcuts.history" = false;
        "browser.search.hiddenOneOffs" =
          "Google"
          + ",Amazon.com"
          + ",Amazon.co.uk"
          + ",Bing"
          + ",Chambers (UK)"
          + ",DuckDuckGo"
          + ",eBay"
          + ",Wikipedia (en)";
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
      };
      userChrome = userChrome;
      userContent = userContent;
    };
  };
}
