{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.ripgrep;
in
{
  options.modules.ripgrep = {
    enable = mkEnableOption "ripgrep";
  };

  config = mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;

      arguments = [
        "--smart-case"
        "--no-heading"
        "--hidden"
        "--iglob=!LICENSE"
        "--glob=!**/.git/**"
        "--glob=!**/.cache/**"
      ];
    };
  };
}
