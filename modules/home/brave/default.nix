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
  imports = [ ./profiles.nix ];

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

    # See https://chromeenterprise.google/policies/ and
    # https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy
    # for the available policies.
    policies = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Enterprise policies fed directly into
        modules.macOSPreferences.apps."com.brave.Browser".forced.
      '';
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

      policies = {
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        BookmarkBarEnabled = false;
        BraveAIChatEnabled = false;
        BraveNewsDisabled = true;
        BraveRewardsDisabled = true;
        BraveStatsPingEnabled = false;
        BraveTalkDisabled = true;
        BraveVPNDisabled = true;
        BraveWalletDisabled = true;
        BrowserSignin = 0;
        HomepageIsNewTabPage = true;
        NewTabPageLocation = "about:blank";
        PasswordManagerEnabled = false;
        SyncDisabled = true;
      };

      profiles.Default = {
        preferences = {
          brave = {
            brave_search."show-ntp-search" = false;
            new_tab_page = {
              background = {
                random = false;
                selected_value = config.modules.colorschemes.palette.primary.background;
                show_background_image = true;
                type = "color";
              };
              show_stats = false;
            };
            show_bookmarks_button = false;
            show_side_panel_button = false;
          };
          # Yes, the typo in the key is from Brave itself.
          ntp.shortcust_visible = false;
          toolbar.pinned_actions = [ ];
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

    modules.macOSPreferences.apps."com.brave.Browser".forced = cfg.policies;

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
