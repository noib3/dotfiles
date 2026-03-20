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

  braveDataDir =
    if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser"
    else
      "${config.xdg.configHome}/BraveSoftware/Brave-Browser";

  # ── Types ──────────────────────────────────────────────────────────────

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
      favicon = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to a favicon image (any format ImageMagick can read).
          The image is converted to 16x16 and 32x32 PNGs at activation
          time and inserted into Brave's Favicons database.
        '';
      };
    };
  };

  profileType = types.submodule {
    options = {
      preferences = mkOption {
        type = types.attrs;
        default = { };
        description = ''
          Nested attrset of Brave JSON preferences for this profile.
          Keys mirror the structure of the Preferences JSON file (e.g.
          `brave.new_tab_page.show_stats = false`). Pinned extension IDs
          are merged automatically.
        '';
      };
      searchEngines = mkOption {
        type = types.attrsOf searchEngineType;
        default = { };
        description = ''
          Custom search engines for this profile. The attribute name is
          used as the keyword (shortcut).
        '';
      };
    };
  };

  # ── Package wrapping ───────────────────────────────────────────────────

  wrappedBrave =
    let
      disableFlags = concatStringsSep "," cfg.disabledFeatures;
    in
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
            --add-flags "--disable-features=${disableFlags}"
        '';
      }
    else
      pkgs.symlinkJoin {
        name = "brave-wrapped";
        paths = [ pkgs.brave ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/brave" \
            --add-flags "--disable-features=${disableFlags}"
        '';
      };

  # ── Extension pinning ──────────────────────────────────────────────────

  pinnedExtensionIds = mapAttrsToList (_: ext: ext.id) (
    filterAttrs (_: ext: ext.pinned) cfg.extensions
  );

  # ── Preferences ────────────────────────────────────────────────────────

  flattenPrefs =
    prefix: attrs:
    concatLists (
      mapAttrsToList (
        k: v:
        let
          path = prefix ++ [ k ];
        in
        if isAttrs v && !(isList v) then
          flattenPrefs path v
        else
          [
            {
              inherit path;
              value = v;
            }
          ]
      ) attrs
    );

  mkPreferencesActivation =
    profileName: profileCfg:
    let
      merged =
        profileCfg.preferences
        // optionalAttrs (pinnedExtensionIds != [ ]) {
          extensions.pinned_extensions = pinnedExtensionIds;
        };

      prefUpdates = builtins.toJSON (flattenPrefs [ ] merged);
      hashName = "brave-preferences-${strings.sanitizeDerivationName profileName}";
    in
    nameValuePair "setBravePreferences-${profileName}" (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        pkgs.callPackage ./set-preferences.nix {
          preferencesPath = "${braveDataDir}/${profileName}/Preferences";
          inherit prefUpdates hashName isDarwin;
          cacheHome = config.xdg.cacheHome;
        }
      )
    );

  # ── Search engines ─────────────────────────────────────────────────────

  mkSearchEnginesActivation =
    profileName: profileCfg:
    let
      hashName = "brave-search-engines-${strings.sanitizeDerivationName profileName}";
    in
    nameValuePair "setBraveSearchEngines-${profileName}" (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        pkgs.callPackage ./set-search-engines.nix {
          engines = profileCfg.searchEngines;
          dbPath = "${braveDataDir}/${profileName}/Web Data";
          faviconsDbPath = "${braveDataDir}/${profileName}/Favicons";
          inherit hashName isDarwin;
          cacheHome = config.xdg.cacheHome;
        }
      )
    );
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

    disabledFeatures = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Chromium feature flags to disable via --disable-features. When
        non-empty the Brave binary is wrapped with a makeWrapper that
        injects the flag.
      '';
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

    profiles = mkOption {
      type = types.attrsOf profileType;
      default = { };
      description = ''
        Per-profile Brave configuration. Keys are profile directory names
        (e.g. "Default", "Profile 1").
      '';
    };
  };

  config = mkIf cfg.enable {
    modules.brave = {
      isDefaultBrowser = true;

      disabledFeatures = [ "GlobalMediaControls" ];

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
            favicon = pkgs.fetchurl {
              url = "https://nixos.org/favicon.ico";
              hash = "sha256-D23q83m1MLh3TuYN2rytTsZ5Aski4LrwA4N16PgYaI4=";
            };
          };
          nixo = {
            name = "NixOS options";
            url = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
            favicon = pkgs.fetchurl {
              url = "https://nixos.org/favicon.ico";
              hash = "sha256-D23q83m1MLh3TuYN2rytTsZ5Aski4LrwA4N16PgYaI4=";
            };
          };
          nixp = {
            name = "Nix packages";
            url = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
            favicon = pkgs.fetchurl {
              url = "https://nixos.org/favicon.ico";
              hash = "sha256-D23q83m1MLh3TuYN2rytTsZ5Aski4LrwA4N16PgYaI4=";
            };
          };
          std = {
            name = "std's docs";
            url = "https://doc.rust-lang.org/nightly/std/?search={searchTerms}";
            favicon = pkgs.fetchurl {
              url = "https://rust-lang.org/logos/rust-logo-blk.svg";
              hash = "sha256-bW4P0p4gFb7Fypvb3BHt4ehPt5LFYFmbWOVkNGgloik=";
            };
          };
        };
      };
    };

    programs.brave = {
      enable = true;
      package = if cfg.disabledFeatures != [ ] then wrappedBrave else pkgs.brave;
      extensions = mapAttrsToList (_: ext: { inherit (ext) id; }) cfg.extensions;
    };

    modules.macOSPreferences.apps."com.brave.Browser".forced = cfg.policies;

    home.activation =
      (
        cfg.profiles
        |> filterAttrs (_: p: p.preferences != { } || pinnedExtensionIds != [ ])
        |> mapAttrs' mkPreferencesActivation
      )
      // (
        cfg.profiles |> filterAttrs (_: p: p.searchEngines != { }) |> mapAttrs' mkSearchEnginesActivation
      )
      // optionalAttrs (isDarwin && cfg.isDefaultBrowser) {
        setBraveAsDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${pkgs.defaultbrowser}/bin/defaultbrowser browser
        '';
      };

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
