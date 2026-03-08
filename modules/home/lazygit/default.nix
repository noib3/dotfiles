{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.lazygit;
in
{
  options.modules.lazygit = {
    enable = mkEnableOption "Lazygit";
  };

  config = mkIf cfg.enable {
    programs.lazygit = {
      enable = true;

      settings = {
        notARepository = "skip";
        git.pagers = [
          {
            colorArg = "always";
            pager = "delta --paging=never";
          }
        ];
        gui = {
          nerdFontsVersion = "3";
          showCommandLog = false;
        };
      };
    };
  };
}
