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
in
{
  options.modules.brave = {
    enable = mkEnableOption "Brave";
  };

  config = mkIf cfg.enable {
    programs.brave = {
      enable = true;
      extensions = [
        { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton Pass
      ];
    };

    # See https://chromeenterprise.google/policies/ and
    # https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy for
    # the available policies.
    modules.macOSPreferences.apps."com.brave.Browser" = {
      forced = {
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
    };

    home.activation = lib.mkIf isDarwin {
      setBraveAsDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.defaultbrowser}/bin/defaultbrowser browser
      '';
      setBravePreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        import ./set-preferences.nix { inherit config pkgs lib; }
      );
      setBraveSearchEngines = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        import ./set-search-engines.nix { inherit config pkgs lib; }
      );
    };

    xdg.mimeApps = lib.mkIf isLinux {
      enable = true;
      defaultApplications = {
        "text/html" = [ "brave.desktop" ];
        "x-scheme-handler/http" = [ "brave.desktop" ];
        "x-scheme-handler/https" = [ "brave.desktop" ];
      };
    };
  };
}
