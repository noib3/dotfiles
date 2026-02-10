{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.opencode;

  opencodePackage =
    (inputs.opencode.packages.${pkgs.stdenv.system}.default).overrideAttrs
      (old: {
        # Add patch from https://github.com/anomalyco/opencode/pull/11300 to be
        # able to set the cursor style and disable blinking.
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url = "https://github.com/anomalyco/opencode/commit/062837c4caf574846c8b4f2b7a43fe2bb21531e8.patch";
            hash = "sha256-oSFUS7PONbcLh/JZHDgcHJhtPRq3Tbl7hE7F/vN6UpI=";
          })
        ];
      });
in
{
  options.modules.opencode = {
    enable = mkEnableOption "OpenCode";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = opencodePackage;
      settings = {
        theme = "system";
        tui = {
          cursor_blink = false;
          cursor_style = "line";
        };
      };
    };
  };
}
