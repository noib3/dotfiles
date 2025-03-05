{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.fish;
in
{
  options.modules.fish = {
    userName = mkOption {
      type = types.str;
    };
  };

  config = {
    # This is needed to have /run/current-system/sw/bin in PATH, which is where
    # `darwin-rebuild` and other nix-darwin-related commands live.
    programs.fish.enable = true;

    users = {
      # https://github.com/LnL7/nix-darwin/issues/1237#issuecomment-2562230471
      knownUsers = [ cfg.userName ];

      users.${cfg.userName} = {
        shell = pkgs.fish;
        # https://github.com/LnL7/nix-darwin/issues/1237#issuecomment-2562242340
        uid = 501;
      };
    };
  };
}
