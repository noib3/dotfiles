{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.brave-policies;

  mkPlist =
    attrs: name:
    pkgs.runCommand name
      {
        nativeBuildInputs = [ pkgs.python3 ];
      }
      ''
        python3 << EOF
        import plistlib
        import json
        policies = json.loads('${builtins.toJSON attrs}')
        with open('$out', 'wb') as f:
            plistlib.dump(policies, f)
        EOF
      '';
in
{
  options.modules.brave-policies = {
    enable = mkEnableOption "Brave policies";
  };

  config = mkIf cfg.enable (
    let
      # See https://chromeenterprise.google/policies/ and
      # https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy
      # for the available policies.
      policies = {
        BookmarkBarEnabled = false;
        BraveAIChatEnabled = false;
        BraveNewsDisabled = true;
        BraveRewardsDisabled = true;
        BraveStatsPingEnabled = false;
        BraveTalkDisabled = true;
        BraveVPNDisabled = true;
        BraveWalletDisabled = true;
        BrowserSignin = 0;
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "DuckDuckGo";
        DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
        HomepageIsNewTabPage = true;
        NewTabPageLocation = "about:blank";
        PasswordManagerEnabled = false;
        SyncDisabled = true;
      };
    in
    {
      system.activationScripts.extraActivation.text =
        let
          managedPrefsPlistFile = mkPlist policies "brave-policies.plist";
          managedPrefsDirPath = "/Library/Managed Preferences";
          managedPrefsPlistPath = "${managedPrefsDirPath}/com.brave.Browser.plist";
        in
        ''
          mkdir -p "${managedPrefsDirPath}"
          chown root:wheel "${managedPrefsDirPath}"
          chmod 755 "${managedPrefsDirPath}"

          cp -f "${managedPrefsPlistFile}" "${managedPrefsPlistPath}"
          chown root:wheel "${managedPrefsPlistPath}"
          chmod 644 "${managedPrefsPlistPath}"

          # See https://github.com/brave/brave-browser/issues/45106#issuecomment-3089894139
          killall cfprefsd || true
        '';
    }
  );
}
