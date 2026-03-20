# Each setting is defined as a typed option together with metadata describing
# where the value should be applied:
#
#   - "policy"  → macOS managed preference (com.brave.Browser forced policy)
#   - "pref"    → JSON preference file (~/.../Brave-Browser/Default/Preferences)
#
# Some policy keys use inverted logic (e.g. BraveNewsDisabled = true means
# news is *off*), so we track that with `inverted = true`.

{ lib }:

with lib;
let
  # Helper: define a setting that maps to a macOS enterprise policy.
  mkPolicySetting =
    {
      description,
      type ? types.bool,
      default,
      policyKey,
      inverted ? false,
    }:
    {
      option = mkOption { inherit description type default; };
      dest = {
        kind = "policy";
        key = policyKey;
        inherit inverted;
      };
    };

  # Helper: define a setting that maps to a Brave JSON preference.
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

  # ── Setting definitions ──────────────────────────────────────────────

  settingsDefs = {
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

    # ── New tab page preferences ───────────────────────────────────────

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
      description = "Whether to use a random background in the new tab page.";
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
      description = "Whether to show the background image in the new tab page.";
      default = true;
      prefPath = [
        "brave"
        "new_tab_page"
        "background"
        "show_background_image"
      ];
    };

    ntp.background.type = mkPrefSetting {
      description = ''The background type for the new tab page (e.g. "color").'';
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

    # ── Toolbar preferences ────────────────────────────────────────────

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

  # ── Public API ─────────────────────────────────────────────────────────

  # Walk the (possibly nested) settingsDefs and extract only the `option`
  # fields, preserving the nesting structure so it can be used directly in
  # `options.modules.brave.settings = { ... }`.
  extractOptions = defs: mapAttrs (_: v: if v ? option then v.option else extractOptions v) defs;

  # Collect all dest metadata paired with a thunk that reads the final
  # value from `cfg.settings`.  Returns a flat list of
  # { dest = { kind, ... }; value = <the configured value>; }.
  collectEntries =
    cfg: prefix: defs:
    concatLists (
      mapAttrsToList (
        name: v:
        let
          attrPath = prefix ++ [ name ];
          value = getAttrFromPath attrPath cfg;
        in
        if v ? dest then
          [
            {
              inherit (v) dest;
              inherit value;
            }
          ]
        else
          collectEntries cfg attrPath v
      ) defs
    );
in
{
  inherit settingsDefs;

  # The options attrset to splice into the submodule.
  options = extractOptions settingsDefs;

  # Given the final `cfg.settings` value, derive policies and preferences.
  mkOutputs =
    settingsCfg:
    let
      entries = collectEntries settingsCfg [ ] settingsDefs;

      policyEntries = filter (e: e.dest.kind == "policy") entries;
      prefEntries = filter (e: e.dest.kind == "pref") entries;
    in
    {
      policies = listToAttrs (
        map (
          e:
          let
            raw = e.value;
            value =
              if e.dest ? inverted && e.dest.inverted then
                !raw
              else if e.dest.key == "BrowserSignin" then
                (if raw then 1 else 0)
              else
                raw;
          in
          nameValuePair e.dest.key value
        ) policyEntries
      );

      preferences = map (e: {
        path = e.dest.path;
        value = e.value;
      }) prefEntries;
    };
}
