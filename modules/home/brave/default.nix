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

  pinnedExtensionIds = mapAttrsToList (_: ext: ext.id) (
    filterAttrs (_: ext: ext.pinned) cfg.extensions
  );

  profile = "Default";

  preferencesPath = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser/${profile}/Preferences";

  dbPath = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser/${profile}/Web Data";
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
      type = types.submoduleWith {
        modules = [ ./search-engines.nix ];
        specialArgs = { inherit pkgs; };
      };
      default = { };
      description = "Custom search engine configuration.";
    };

    settings = mkOption {
      type = types.submoduleWith {
        modules = [ ./settings.nix ];
        specialArgs = { inherit pkgs; };
      };
      default = { };
      description = "Brave browser settings.";
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

      searchEngines.engines = {
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
        # Forward pinned extension IDs into the settings submodule so they
        # end up in the JSON preference updates.
        _pinnedExtensionIds = pinnedExtensionIds;

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

    # See https://chromeenterprise.google/policies/ and
    # https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy
    # for the available policies.
    modules.macOSPreferences.apps."com.brave.Browser".forced = cfg.settings._policies;

    home.activation = mkIf isDarwin (
      {
        setBravePreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          is_brave_running() {
            /usr/bin/pgrep -x "Brave Browser" > /dev/null 2>&1
          }

          apply_brave_preferences() {
            # Exit early if Preferences doesn't exist yet.
            [[ -f "${preferencesPath}" ]] || return 0

            # Generate the checksum of the preference updates.
            pref_hash=$(echo -n '${cfg.settings._prefUpdates}' | ${pkgs.openssl}/bin/openssl dgst -sha256 | cut -d' ' -f2)
            hash_file="${config.xdg.cacheHome}/home-manager/brave-preferences.hash"

            # Exit early if the preferences haven't changed.
            if [[ -f "$hash_file" ]] && [[ "$(cat "$hash_file")" == "$pref_hash" ]]; then
              echo "Brave preferences already up to date"
              return 0
            fi

            # Brave writes the Preferences file on exit, so we need to quit
            # it first.
            brave_was_running=0
            if is_brave_running; then
              brave_was_running=1
              run /usr/bin/osascript -e 'quit app "Brave Browser"'
              while is_brave_running; do /bin/sleep 0.5; done
            fi

            # Apply each preference update.
            run ${pkgs.jq}/bin/jq \
              --argjson updates '${cfg.settings._prefUpdates}' \
              'reduce $updates[] as $update (.; setpath($update.path; $update.value))' \
              "${preferencesPath}" > "${preferencesPath}.tmp"

            run mv "${preferencesPath}.tmp" "${preferencesPath}"

            # Restart Brave if it was running.
            if [[ "$brave_was_running" -eq 1 ]]; then
              run /usr/bin/open -a "Brave Browser"
            fi

            # Store the hash.
            run mkdir -p "$(dirname "$hash_file")"
            run echo "$pref_hash" > "$hash_file"
          }

          apply_brave_preferences
        '';

        setBraveSearchEngines = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          is_brave_running() {
            /usr/bin/pgrep -x "Brave Browser" > /dev/null 2>&1
          }

          apply_brave_search_engines() {
            # Exit early if Brave hasn't yet created the DB.
            [[ -f "${dbPath}" ]] || return 0

            # Generate the checksum of the SQL script.
            script_hash=$(${pkgs.openssl}/bin/openssl dgst -sha256 ${cfg.searchEngines._sqlScript} | cut -d' ' -f2)
            hash_file="${config.xdg.cacheHome}/home-manager/brave-search-engines.hash"

            # Exit early if the search engines haven't changed.
            if [[ -f "$hash_file" ]] && [[ "$(cat "$hash_file")" == "$script_hash" ]]; then
              echo "Brave search engines already up to date"
              return 0
            fi

            # The database is locked while Brave is running, so we need to
            # quit it first.
            brave_was_running=0
            if is_brave_running; then
              brave_was_running=1
              run /usr/bin/osascript -e 'quit app "Brave Browser"'
              while is_brave_running; do /bin/sleep 0.5; done
            fi

            # Apply SQL changes.
            run ${pkgs.sqlite}/bin/sqlite3 "${dbPath}" < ${cfg.searchEngines._sqlScript}

            # Restart Brave if it was running.
            if [[ "$brave_was_running" -eq 1 ]]; then
              run /usr/bin/open -a "Brave Browser"
            fi

            # Store the hash.
            run mkdir -p "$(dirname "$hash_file")"
            run echo "$script_hash" > "$hash_file"
          }

          apply_brave_search_engines
        '';
      }
      // optionalAttrs cfg.isDefaultBrowser {
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
