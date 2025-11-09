{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.claude;
in
{
  options.modules.claude = {
    enable = mkEnableOption "Claude Code";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.claude-code
      (import ./claude-code-acp.nix { inherit pkgs; })
    ];

    modules.nixpkgs.allowUnfreePackages = [ (lib.getName pkgs.claude-code) ];
  };
}
