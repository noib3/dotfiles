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

  settingsMod = import ./settings.nix { inherit lib; };
  outputs = settingsMod.mkOutputs cfg.settings;

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

  searchEngineType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Display name of the search engine.";
      };
      url = mkOption {
        type = types.str;
        description = "Search URL template. Use {searchTerms} as placeholder.";
      };
      favicon_url = mkOption {
        type = types.str;
        default = "";
        description = "URL to the search engine's favicon.";
      };
    };
  };

  pinnedExtensionIds = mapAttrsToList (_: ext: ext.id) (
    filterAttrs (_: ext: ext.pinned) cfg.extensions
  );

  # Merge the extension-pinning preference into the preferences coming from
  # the settings submodule.
  allPreferences =
    outputs.preferences
    ++ optional (pinnedExtensionIds != [ ]) {
      path = [
        "extensions"
        "pinned_extensions"
      ];
      value = pinnedExtensionIds;
    };
in
{
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

    searchEngines = mkOption {
      type = types.attrsOf searchEngineType;
      default = { };
      description = ''
        Custom search engines. The attribute name is used as the keyword
        (shortcut) for the engine.
      '';
    };

    settings = settingsMod.options;
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
        ntp.background.color = config.modules.colorschemes.palette.primary.background;
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

    # See https://chromeenterprise.google/policies/ and
    # https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy for
    # the available policies.
    modules.macOSPreferences.apps."com.brave.Browser" = {
      forced = outputs.policies;
    };

    home.activation = lib.mkIf isDarwin (
      {
        setBravePreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          import ./set-preferences.nix {
            inherit config pkgs lib;
            preferences = allPreferences;
          }
        );
        setBraveSearchEngines = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          import ./set-search-engines.nix {
            inherit config pkgs lib;
            searchEngines = cfg.searchEngines;
          }
        );
      }
      // optionalAttrs cfg.isDefaultBrowser {
        setBraveAsDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${pkgs.defaultbrowser}/bin/defaultbrowser browser
        '';
      }
    );

    xdg.mimeApps = lib.mkIf (isLinux && cfg.isDefaultBrowser) {
      enable = true;
      defaultApplications = {
        "text/html" = [ "brave.desktop" ];
        "x-scheme-handler/http" = [ "brave.desktop" ];
        "x-scheme-handler/https" = [ "brave.desktop" ];
      };
    };
  };
}
