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

  # ── Types ──

  extensionType = types.submodule {
    options = {
      id = mkOption {
        type = types.singleLineStr;
        description = "Chrome Web Store extension ID";
      };
      pinned = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to pin this extension to the toolbar";
      };
    };
  };

  searchEngineType = types.submodule {
    options = {
      name = mkOption {
        type = types.singleLineStr;
        description = "Display name of the search engine";
      };
      url = mkOption {
        type = types.singleLineStr;
        description = "Search URL template. Use {searchTerms} as placeholder";
      };
      favicon = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to a favicon image, in any format ImageMagick can read
        '';
      };
    };
  };

  profileType = types.submodule {
    options = {
      preferences = mkOption {
        type = types.attrs;
        default = { };
        description = "Nested attrset of Brave JSON preferences for this profile";
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

  # ── Package wrapping ──

  needsWrapping = cfg.features.enabled != [ ] || cfg.features.disabled != [ ];

  wrappedBrave =
    let
      enableFlags = cfg.features.enabled |> concatStringsSep ",";
      disableFlags = cfg.features.disabled |> concatStringsSep ",";
      featuresFlags =
        optional (cfg.features.enabled != [ ]) "--enable-features=${enableFlags}"
        ++ optional (cfg.features.disabled != [ ]) "--disable-features=${disableFlags}"
        |> concatStringsSep " ";
    in
    if isDarwin then
      pkgs.symlinkJoin {
        name = "brave-wrapped";
        paths = [ pkgs.brave ];
        postBuild =
          let
            darwinLauncher = pkgs.runCommandCC "brave-darwin-launcher" { } ''
              $CC -DBRAVE_FEATURES_FLAGS=${escapeShellArg (builtins.toJSON featuresFlags)} \
                "${./darwin-launcher.c}" -o "$out"
            '';
          in
          ''
            appBundle="$out/Applications/Brave Browser.app"
            appExecutable="$appBundle/Contents/MacOS/Brave Browser"
            originalExecutable="$appBundle/Contents/MacOS/Brave Browser.orig"

            cp --dereference "$appExecutable" "$originalExecutable"
            rm "$appExecutable"
            cp "${darwinLauncher}" "$appExecutable"

            chmod 755 "$appExecutable"
          '';
      }
    else
      pkgs.symlinkJoin {
        name = "brave-wrapped";
        paths = [ pkgs.brave ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/brave" \
            --add-flags "${featuresFlags}"
        '';
      };

  # ── Per-profile activation entries ──

  pinnedExtensionIds = mapAttrsToList (_: ext: ext.id) (
    filterAttrs (_: ext: ext.pinned) cfg.extensions
  );

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
      sanitized = strings.sanitizeDerivationName profileName;
    in
    nameValuePair "setBravePreferences-${profileName}" (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        pkgs.callPackage ./set-preferences.nix {
          preferencesPath = "${braveDataDir}/${profileName}/Preferences";
          prefUpdates = builtins.toJSON (flattenPrefs [ ] merged);
          hashFile = "${config.xdg.cacheHome}/home-manager/brave-preferences-${sanitized}.hash";
          inherit isDarwin;
        }
      )
    );

  mkSearchEnginesActivation =
    profileName: profileCfg:
    let
      sanitized = strings.sanitizeDerivationName profileName;
    in
    nameValuePair "setBraveSearchEngines-${profileName}" (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        pkgs.callPackage ./set-search-engines.nix {
          engines = profileCfg.searchEngines;
          dbPath = "${braveDataDir}/${profileName}/Web Data";
          faviconsDbPath = "${braveDataDir}/${profileName}/Favicons";
          hashFile = "${config.xdg.cacheHome}/home-manager/brave-search-engines-${sanitized}.hash";
          inherit isDarwin;
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
      description = "Whether to set Brave as the default browser";
    };

    extensions = mkOption {
      type = types.attrsOf extensionType;
      default = { };
      description = "Extensions to install, keyed by a human-readable name";
    };

    features = {
      enabled = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Chromium feature flags to enable via --enable-features";
      };
      disabled = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Chromium feature flags to disable via --disable-features";
      };
    };

    # See https://chromeenterprise.google/policies/ and
    # https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy for
    # the available policies.
    policies = mkOption {
      type = types.attrs;
      default = { };
      description = "Enterprise policies";
    };

    profiles = mkOption {
      type = types.attrsOf profileType;
      default = { };
      description = ''
        Per-profile Brave configuration. Keys are profile directory names
        (e.g. "Default", "Profile-1", etc.).
      '';
    };
  };

  config = mkIf cfg.enable {
    modules.brave = {
      isDefaultBrowser = true;

      features = {
        enabled = [ "BraveEnableAutoTranslate" ];
        disabled = [ "GlobalMediaControls" ];
      };

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
          # Chromium stores the default zoom as log(zoom_factor)/log(1.2), so
          # for 130% we have log(1.3)/(log1.2) ~= 1.43902.
          partition.default_zoom_level.x = 1.43902;
          toolbar.pinned_actions = [ ];
        };

        searchEngines =
          let
            nixFavicon = pkgs.fetchurl {
              url = "https://nixos.org/favicon.svg";
              hash = "sha256-UL/Eyk/e7Yrfz8uR9MZwB80a+S4HC9CjixpW8tpJMvY=";
            };
          in
          {
            hm = {
              name = "Home Manager Options";
              url = "https://home-manager-options.extranix.com/?query={searchTerms}";
              favicon = nixFavicon;
            };
            nixo = {
              name = "NixOS options";
              url = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
              favicon = nixFavicon;
            };
            nixp = {
              name = "Nix packages";
              url = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
              favicon = nixFavicon;
            };
            std =
              let
                rustFavicon = pkgs.fetchurl {
                  name = "rust-favicon.svg";
                  url = "https://rust-lang.org/static/images/favicon.svg";
                  hash = "sha256-BEvjkUSrMEz56g6QFMP0duDFGUxiqlJbNmnK9dtawIg=";
                };
                rustFaviconWhite = pkgs.runCommand "rust-favicon-white.png" { } ''
                  ${lib.getExe' pkgs.imagemagick "magick"} \
                    -density 384 -background none "${rustFavicon}" \
                    -fill white -colorize 100 \
                    PNG32:"$out"
                '';
              in
              {
                name = "std's docs";
                url = "https://doc.rust-lang.org/nightly/std/?search={searchTerms}";
                favicon = rustFaviconWhite;
              };
          };
      };
    };

    programs.brave = {
      enable = true;
      package = if needsWrapping then wrappedBrave else pkgs.brave;
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
        cfg.profiles
        |> filterAttrs (_: p: p.searchEngines != { })
        |> mapAttrs' mkSearchEnginesActivation
      )
      // optionalAttrs (isDarwin && needsWrapping) {
        codesignBraveAppBundle = lib.hm.dag.entryAfter [ "copyApps" ] (
          let
            braveAppBundlePath = "${config.home.homeDirectory}/Applications/Home Manager Apps/Brave Browser.app";
          in
          ''
            if [[ -d "${braveAppBundlePath}" ]]; then
              if ! /usr/bin/codesign --verify --deep --strict --verbose=0 "${braveAppBundlePath}" >/dev/null 2>&1; then
                run /usr/bin/xattr -cr "${braveAppBundlePath}"
                run /usr/bin/codesign --force --deep --sign - "${braveAppBundlePath}" >/dev/null 2>&1
              fi
            fi
          ''
        );
      }
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
