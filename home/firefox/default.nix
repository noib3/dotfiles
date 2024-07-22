{ colorscheme
, font-family
, machine
, palette
, hexlib
, lib
}:

let
  colors = import ./colors.nix { inherit colorscheme palette hexlib; };
  font = import ./font.nix { inherit machine; family = font-family; };
  extensions = import ./extensions.nix;
in
{
  profiles = {
    home = {
      # extensions = with extensions; [
      #   bitwarden
      #   # downloads-sidebar
      #   # tridactyl-no-new-tab
      # ];

      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "apz.allow_zooming" = true;
        "browser.aboutConfig.showWarning" = false;
        "browser.tabs.warnOnClose" = false;
        "browser.fullscreen.autohide" = false;
        "browser.newtabpage.pinned" = "";
        "browser.startup.homepage" = "https://google.com";
        "browser.tabs.loadInBackground" = false;
        "browser.urlbar.update2" = false;
        "browser.urlbar.shortcuts.bookmarks" = false;
        "browser.urlbar.shortcuts.tabs" = false;
        "browser.urlbar.shortcuts.history" = false;
        "browser.search.hiddenOneOffs" =
          lib.concatStringsSep "," [
            "Google"
            "Amazon.com"
            "Amazon.co.uk"
            "Bing"
            "Chambers (UK)"
            "DuckDuckGo"
            "eBay"
            "Wikipedia (en)"
          ];
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
      };

      userContent = ''
        @-moz-document url-prefix(about:blank) {
          * {
            background-color: ${colors.about-blank.bg} !important;
          }
        }
      '';

      userChrome = ''
        * {
          font-family: "${font.family}";
          font-size: ${builtins.toString font.size}px !important;
        }

        :root {
          --color-unfocused-tabs-bg: ${colors.tabs.unfocused.bg};
          --color-unfocused-tabs-fg: ${colors.tabs.unfocused.fg};

          --color-focused-tabs-bg: ${colors.tabs.focused.bg};
          --color-focused-tabs-fg: ${colors.tabs.focused.fg};

          --color-urlbar-bg: ${colors.urlbar.bg};
          --color-urlbar-fg: ${colors.urlbar.fg};
          --color-urlbar-popup-url: ${colors.urlbar.urls.fg};
          --color-urlbar-separator: ${colors.urlbar.separator};

          --color-urlbar-selected-bg: ${colors.urlbar.selected.bg};
          --color-urlbar-selected-fg: ${colors.urlbar.selected.fg};
          --color-urlbar-selected-popup_url: ${colors.urlbar.selected.fg};

          --color-sidebar-bg: ${colors.sidebar.bg};
          --color-sidebar-fg: ${colors.sidebar.fg};
        }
      ''
      + builtins.readFile ./colors.css
      + builtins.readFile ./tabbar/debloat-tabbar.css
      + builtins.readFile ./tabbar/tabbar-layout.css
      + builtins.readFile ./tabbar/tabs-fill-available-width.css
      + builtins.readFile ./tabbar/numbered-tabs.css
      + builtins.readFile ./tabbar/tab-close-button-always-on-hover.css
      + builtins.readFile ./tabbar/hide-tabs-with-one-tab.css
      + builtins.readFile ./navbar/debloat-navbar.css
      + builtins.readFile ./navbar/navbar-layout.css
      + builtins.readFile ./navbar/navbar-on-focus.css
      + builtins.readFile ./urlbar/debloat-urlbar.css
      + builtins.readFile ./urlbar/urlbar-layout.css
      + builtins.readFile ./urlbar/remove-megabar.css
      + builtins.readFile ./sidebar/debloat-sidebar.css
      + builtins.readFile ./sidebar/sidebar-layout.css
      + ''
        #PersonalToolbar {
          display: none !important;
        }
      '';
    };
  };
}
