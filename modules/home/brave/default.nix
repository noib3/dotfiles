{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.brave;
  inherit (pkgs.stdenv) isDarwin isLinux;

  extensionType = types.submodule {
    options = {
      id = mkOption {
        type = types.str;
        description = "Chrome Web Store extension ID.";
      };
      pinned = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to pin this extension to the toolbar.";
      };
    };
  };
in
{
  imports = [
    ./settings.nix
    ./search-engines.nix
  ];

  options.modules.brave = {
    enable = mkEnableOption "Brave";

    isDefaultBrowser = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to set Brave as the default browser.";
    };

    extensions = mkOption {
      type = types.attrsOf extensionType;
      default = { };
      description = "Extensions to install, keyed by a human-readable name.";
    };
  };

  config = mkIf cfg.enable {
    modules.brave = {
      isDefaultBrowser = true;

      extensions = {
        proton-pass = {
          id = "ghmbeldphafepmbegfdlkpapadhbakde";
          pinned = true;
        };
        unhook.id = "khncfooichmfjbepaaaebmommgaepoid";
      };

      searchEngines = {
        hm = {
          name = "Home Manager Options";
          url = "https://home-manager-options.extranix.com/?query={searchTerms}";
          favicon_url = "https://nixos.org/favicon.ico";
        };
        nixo = {
          name = "NixOS options";
          url = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
          favicon_url = "https://nixos.org/favicon.ico";
        };
        nixp = {
          name = "Nix packages";
          url = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
          favicon_url = "https://nixos.org/favicon.ico";
        };
        std = {
          name = "std's docs";
          url = "https://doc.rust-lang.org/nightly/std/?search={searchTerms}";
          favicon_url = "https://rust-lang.org/logos/rust-logo-blk.svg";
        };
      };

      settings = {
        # ── Policies ─────────────────────────────────────────────────────
        autofill.address = false;
        autofill.creditCard = false;
        bookmarkBar = false;
        braveAIChat = false;
        braveNews = false;
        braveRewards = false;
        braveStatsPing = false;
        braveTalk = false;
        braveVPN = false;
        braveWallet = false;
        browserSignin = false;
        homepageIsNewTabPage = true;
        newTabPageLocation = "about:blank";
        passwordManager = false;
        sync = false;

        # ── JSON preferences ─────────────────────────────────────────────
        ntp.showSearchBox = false;
        ntp.background.random = false;
        ntp.background.color = config.modules.colorschemes.palette.primary.background;
        ntp.background.showImage = true;
        ntp.background.type = "color";
        ntp.showStats = false;
        ntp.showTopSites = false;
        showBookmarksButton = false;
        showSidePanelButton = false;
        toolbar.pinnedActions = [ ];
      };
    };

    programs.brave = {
      enable = true;
      package =
        if isDarwin then
          pkgs.symlinkJoin {
            name = "brave-wrapped";
            paths = [ pkgs.brave ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              rm "$out/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
              makeWrapper \
                "${pkgs.brave}/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
                "$out/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
                --add-flags "--disable-features=GlobalMediaControls"
            '';
          }
        else
          pkgs.brave;
      extensions = mapAttrsToList (_: ext: { inherit (ext) id; }) cfg.extensions;
    };

    home.activation = mkIf isDarwin (
      optionalAttrs cfg.isDefaultBrowser {
        setBraveAsDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${pkgs.defaultbrowser}/bin/defaultbrowser browser
        '';
      }
    );

    xdg.mimeApps = mkIf (isLinux && cfg.isDefaultBrowser) {
      enable = true;
      defaultApplications = {
        "text/html" = [ "brave.desktop" ];
        "x-scheme-handler/http" = [ "brave.desktop" ];
        "x-scheme-handler/https" = [ "brave.desktop" ];
      };
    };
  };
}
