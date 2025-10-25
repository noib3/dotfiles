{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.brave-policies;
in
{
  options.modules.brave-policies = {
    enable = mkEnableOption "Brave policies";
  };

  config = mkIf cfg.enable {
    # See https://chromeenterprise.google/policies/ and
    # https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy for
    # the available policies.
    system.defaults.CustomUserPreferences."com.brave.Browser" = {
      DefaultSearchProviderEnabled = true;
      DefaultSearchProviderName = "DuckDuckGo";
      DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
      DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
    };
  };
}
