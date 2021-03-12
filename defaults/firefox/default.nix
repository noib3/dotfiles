{ font, colors }:
let
  userChrome = ''
    * {
      font-family: "${font.family}";
      font-size: ${font.size} !important;
    }

    :root {
      __color_unfocused_tabs_bg: ${colors.unfocused_tabs_bg};
      __color_unfocused_tabs_fg: ${colors.unfocused_tabs_fg};
      __color_focused_tabs_bg: ${colors.focused_tabs_bg};
      __color_focused_tabs_fg: ${colors.focused_tabs_fg};
      __color_urlbar_separator: ${colors.urlbar_separator};
      __color_urlbar_bg: ${colors.urlbar_bg};
      __color_urlbar_fg: ${colors.urlbar_fg};
      __color_urlbar_popup_url: ${colors.urlbar_popup_url};
      __color_urlbar_selected_bg: ${colors.urlbar_selected_bg};
      __color_urlbar_selected_fg: ${colors.urlbar_selected_fg};
      __color_urlbar_selected_popup_url: ${colors.urlbar_selected_popup_url};
      __color_sidebar_bg: ${colors.sidebar_bg};
      __color_sidebar_fg: ${colors.sidebar_fg};
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
        background-color: ${colors.about_blank_bg} !important;
      }
    }
  '';
in
{
  extensions = with (import ./extensions.nix); [
    bitwarden
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
