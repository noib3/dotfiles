# Brave settings submodule.
#
# Each setting is a typed option that knows where it needs to be applied:
#
#   - "policy" → macOS managed preference (com.brave.Browser forced policy)
#   - "pref"   → Brave's JSON Preferences file (~/.../Default/Preferences)
#
# The submodule exposes two read-only outputs that the parent module uses
# to wire into the right destinations:
#
#   - _policies     → fed into modules.macOSPreferences
#   - _prefUpdates  → fed into a home.activation script

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
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
    cfg: prefix: defs:
    concatLists (
      mapAttrsToList (
        name: v:
        let
          path = prefix ++ [ name ];
          value = getAttrFromPath path cfg;
        in
        if v ? dest then
          [
            {
              inherit (v) dest;
              inherit value;
            }
          ]
        else
          collectEntries cfg path v
      ) defs
    );

  entries = collectEntries config [ ] settingsDefs;

  policyEntries = filter (e: e.dest.kind == "policy") entries;
  prefEntries = filter (e: e.dest.kind == "pref") entries;
in
{
  options = (extractOptions settingsDefs) // {
    # Private option set by the parent to forward pinned extension IDs
    # into the preference updates.
    _pinnedExtensionIds = mkOption {
      type = types.listOf types.str;
      default = [ ];
      internal = true;
    };

    # Read-only outputs consumed by the parent module.
    _policies = mkOption {
      type = types.attrs;
      readOnly = true;
      internal = true;
      description = "Computed macOS enterprise policies.";
    };

    _prefUpdates = mkOption {
      type = types.str;
      readOnly = true;
      internal = true;
      description = "JSON-encoded list of {path, value} preference patches.";
    };
  };

  config = {
    _policies = listToAttrs (
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

    _prefUpdates = builtins.toJSON (
      (map (e: {
        inherit (e.dest) path;
        inherit (e) value;
      }) prefEntries)
      ++ optional (config._pinnedExtensionIds != [ ]) {
        path = [
          "extensions"
          "pinned_extensions"
        ];
        value = config._pinnedExtensionIds;
      }
    );
  };
}
