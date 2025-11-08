{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.claude;
  pkg = pkgs.claude-code;
in
{
  options.modules.claude = {
    enable = mkEnableOption "Claude Code";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkg ];
    modules.nixpkgs.allowUnfreePackages = [ (lib.getName pkg) ];
  };
}
