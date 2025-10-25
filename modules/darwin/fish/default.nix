{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.fish;
  inherit (config.modules.desktop) userName;
in
{
  options.modules.fish = {
    enable = mkEnableOption "Fish";
  };

  config = mkIf cfg.enable {
    # This is needed to have /run/current-system/sw/bin in $PATH, which is
    # where `darwin-rebuild` and other nix-darwin-related commands live.
    programs.fish.enable = true;

    users = {
      # https://github.com/LnL7/nix-darwin/issues/1237#issuecomment-2562230471
      knownUsers = [ userName ];

      users.${userName} = {
        shell = pkgs.fish;
        # https://github.com/LnL7/nix-darwin/issues/1237#issuecomment-2562242340
        uid = 501;
      };
    };
  };
}
