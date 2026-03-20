# Brave settings module.
#
# Each setting is a typed option that knows where it needs to be applied:
#
#   - "policy" → macOS managed preference (com.brave.Browser forced policy)
#   - "pref"   → Brave's JSON Preferences file (~/.../Default/Preferences)
#
# The config section wires everything to the right destinations: policies
# go to modules.macOSPreferences, preferences go to a home.activation
# script that patches the JSON file with jq.

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.brave;
  inherit (pkgs.stdenv) isDarwin;

  # ── Helpers ────────────────────────────────────────────────────────────

  mkPolicySetting =
    {
      description,
      type ? types.bool,
      default,
      policyKey,
      inverted ? false,
      transform ? null,
    }:
    {
      option = mkOption { inherit description type default; };
      dest = {
        kind = "policy";
        key = policyKey;
        inherit inverted transform;
      };
    };

  mkPrefSetting =
    {
      description,
      type ? types.bool,
      default,
      prefPath,
    }:
    {
      option = mkOption { inherit description type default; };
      dest = {
        kind = "pref";
        path = prefPath;
      };
    };

  # ── Setting definitions ────────────────────────────────────────────────

  settingsDefs = {

    # ── Policies ─────────────────────────────────────────────────────────

    autofill.address = mkPolicySetting {
      description = "Whether to enable autofill for addresses.";
      default = false;
      policyKey = "AutofillAddressEnabled";
    };

    autofill.creditCard = mkPolicySetting {
      description = "Whether to enable autofill for credit cards.";
      default = false;
      policyKey = "AutofillCreditCardEnabled";
    };

    bookmarkBar = mkPolicySetting {
      description = "Whether to show the bookmark bar.";
      default = false;
      policyKey = "BookmarkBarEnabled";
    };

    braveAIChat = mkPolicySetting {
      description = "Whether to enable Brave's AI chat (Leo).";
      default = false;
      policyKey = "BraveAIChatEnabled";
    };

    braveNews = mkPolicySetting {
      description = "Whether to enable Brave News.";
      default = false;
      policyKey = "BraveNewsDisabled";
      inverted = true;
    };

    braveRewards = mkPolicySetting {
      description = "Whether to enable Brave Rewards.";
      default = false;
      policyKey = "BraveRewardsDisabled";
      inverted = true;
    };

    braveStatsPing = mkPolicySetting {
      description = "Whether to enable Brave stats ping.";
      default = false;
      policyKey = "BraveStatsPingEnabled";
    };

    braveTalk = mkPolicySetting {
      description = "Whether to enable Brave Talk.";
      default = false;
      policyKey = "BraveTalkDisabled";
      inverted = true;
    };

    braveVPN = mkPolicySetting {
      description = "Whether to enable Brave VPN.";
      default = false;
      policyKey = "BraveVPNDisabled";
      inverted = true;
    };

    braveWallet = mkPolicySetting {
      description = "Whether to enable Brave Wallet.";
      default = false;
      policyKey = "BraveWalletDisabled";
      inverted = true;
    };

    browserSignin = mkPolicySetting {
      description = "Whether to allow browser sign-in.";
      default = false;
      policyKey = "BrowserSignin";
      transform = v: if v then 1 else 0;
    };

    homepageIsNewTabPage = mkPolicySetting {
      description = "Whether the homepage is the new tab page.";
      default = true;
      policyKey = "HomepageIsNewTabPage";
    };

    newTabPageLocation = mkPolicySetting {
      description = "URL to load in the new tab page.";
      type = types.str;
      default = "about:blank";
      policyKey = "NewTabPageLocation";
    };

    passwordManager = mkPolicySetting {
      description = "Whether to enable the built-in password manager.";
      default = false;
      policyKey = "PasswordManagerEnabled";
    };

    sync = mkPolicySetting {
      description = "Whether to enable Brave Sync.";
      default = false;
      policyKey = "SyncDisabled";
      inverted = true;
    };

    # ── JSON preferences ─────────────────────────────────────────────────

    ntp.showSearchBox = mkPrefSetting {
      description = "Whether to show the search box in the new tab page.";
      default = false;
      prefPath = [
        "brave"
        "brave_search"
        "show-ntp-search"
      ];
    };

    ntp.background.random = mkPrefSetting {
      description = "Whether to use a random NTP background.";
      default = false;
      prefPath = [
        "brave"
        "new_tab_page"
        "background"
        "random"
      ];
    };

    ntp.background.color = mkPrefSetting {
      description = "Background color for the new tab page (hex string).";
      type = types.str;
      default = "#000000";
      prefPath = [
        "brave"
        "new_tab_page"
        "background"
        "selected_value"
      ];
    };

    ntp.background.showImage = mkPrefSetting {
      description = "Whether to show a background image in the new tab page.";
      default = true;
      prefPath = [
        "brave"
        "new_tab_page"
        "background"
        "show_background_image"
      ];
    };

    ntp.background.type = mkPrefSetting {
      description = ''The NTP background type (e.g. "color").'';
      type = types.str;
      default = "color";
      prefPath = [
        "brave"
        "new_tab_page"
        "background"
        "type"
      ];
    };

    ntp.showStats = mkPrefSetting {
      description = "Whether to show stats in the new tab page.";
      default = false;
      prefPath = [
        "brave"
        "new_tab_page"
        "show_stats"
      ];
    };

    ntp.showTopSites = mkPrefSetting {
      description = "Whether to show top sites in the new tab page.";
      default = false;
      # Yes, the typo in the key is from Brave itself.
      prefPath = [
        "ntp"
        "shortcust_visible"
      ];
    };

    showBookmarksButton = mkPrefSetting {
      description = "Whether to show the bookmarks button in the toolbar.";
      default = false;
      prefPath = [
        "brave"
        "show_bookmarks_button"
      ];
    };

    showSidePanelButton = mkPrefSetting {
      description = "Whether to show the side panel button in the toolbar.";
      default = false;
      prefPath = [
        "brave"
        "show_side_panel_button"
      ];
    };

    toolbar.pinnedActions = mkPrefSetting {
      description = "List of actions pinned to the toolbar.";
      type = types.listOf types.str;
      default = [ ];
      prefPath = [
        "toolbar"
        "pinned_actions"
      ];
    };
  };

  # ── Extract / collect ──────────────────────────────────────────────────

  extractOptions = defs: mapAttrs (_: v: if v ? option then v.option else extractOptions v) defs;

  collectEntries =
    cfgValues: prefix: defs:
    concatLists (
      mapAttrsToList (
        name: v:
        let
          path = prefix ++ [ name ];
          value = getAttrFromPath path cfgValues;
        in
        if v ? dest then
          [
            {
              inherit (v) dest;
              inherit value;
            }
          ]
        else
          collectEntries cfgValues path v
      ) defs
    );

  entries = collectEntries cfg.settings [ ] settingsDefs;

  policyEntries = filter (e: e.dest.kind == "policy") entries;
  prefEntries = filter (e: e.dest.kind == "pref") entries;

  # ── Policies ───────────────────────────────────────────────────────────

  policies = listToAttrs (
    map (
      e:
      let
        raw = e.value;
        value =
          if e.dest.transform != null then
            e.dest.transform raw
          else if e.dest.inverted then
            !raw
          else
            raw;
      in
      nameValuePair e.dest.key value
    ) policyEntries
  );

  # ── JSON preferences ──────────────────────────────────────────────────

  pinnedExtensionIds = mapAttrsToList (_: ext: ext.id) (
    filterAttrs (_: ext: ext.pinned) cfg.extensions
  );

  preferences =
    (map (e: {
      inherit (e.dest) path;
      inherit (e) value;
    }) prefEntries)
    ++ optional (pinnedExtensionIds != [ ]) {
      path = [
        "extensions"
        "pinned_extensions"
      ];
      value = pinnedExtensionIds;
    };

  prefUpdates = builtins.toJSON preferences;

  profile = "Default";

  preferencesPath = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser/${profile}/Preferences";
in
{
  options.modules.brave.settings = extractOptions settingsDefs;

  config = mkIf cfg.enable {
    # See https://chromeenterprise.google/policies/ and
    # https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy
    # for the available policies.
    modules.macOSPreferences.apps."com.brave.Browser".forced = policies;

    home.activation = mkIf isDarwin {
      setBravePreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        is_brave_running() {
          /usr/bin/pgrep -x "Brave Browser" > /dev/null 2>&1
        }

        apply_brave_preferences() {
          # Exit early if Preferences doesn't exist yet.
          [[ -f "${preferencesPath}" ]] || return 0

          # Generate the checksum of the preference updates.
          pref_hash=$(echo -n '${prefUpdates}' | ${pkgs.openssl}/bin/openssl dgst -sha256 | cut -d' ' -f2)
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
            --argjson updates '${prefUpdates}' \
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
    };
  };
}
