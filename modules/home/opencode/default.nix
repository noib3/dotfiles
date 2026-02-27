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
        # Apply a patched version of
        # https://github.com/anomalyco/opencode/pull/11300 to set the cursor
        # style and disable blinking in the TUI.
        patches = (old.patches or [ ]) ++ [
          ./patches/cursor-style-and-blink.patch
        ];

        # Nixpkgs' version of Bun is 1.3.9, so we need to patch the expected
        # version range to allow Opencode to run with that version (upstream
        # requires `^1.3.10`).
        postPatch = (old.postPatch or "") + ''
          substituteInPlace packages/script/src/index.ts \
            --replace-fail 'const expectedBunVersionRange = `^''${expectedBunVersion}`' 'const expectedBunVersionRange = `>=1.3.9`'
        '';
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
          scroll_acceleration.enabled = true;
        };
      };
    };
  };
}
