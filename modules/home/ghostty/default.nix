{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  inherit (pkgs.stdenv) isDarwin isLinux;
  cfg = config.modules.ghostty;
  package = if isDarwin then pkgs.brewCasks.ghostty else pkgs.ghostty;
  terminfoEntry = "xterm-ghostty";
in
{
  options.modules.ghostty = {
    enable = mkEnableOption "Ghostty";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      inherit package;
      enable = true;
      settings = {
        adjust-cursor-thickness = "200%";
        auto-update = "off";
        clipboard-read = "allow";
        cursor-style = "bar";
        cursor-style-blink = false;
        env =
          {
            TERM = terminfoEntry;
          }
          // lib.attrsets.optionalAttrs config.modules.terminfo.enable {
            # Ghostty exports its own $TERMINFO path by default, so we need to
            # override it to use the Home Manager-managed terminfo directory.
            TERMINFO = config.modules.terminfo.directory;
          }
          |> lib.mapAttrsToList (name: value: "${name}=${value}");
        keybind = import ./keybinds.nix { inherit lib isDarwin isLinux; };
        quit-after-last-window-closed = true;
        # Without this the cursor will still blink, even if cursor-style-blink
        # is set to false. See https://github.com/ghostty-org/ghostty/discussions/2812
        # for more infos.
        shell-integration-features = "no-cursor";
        window-padding-x = 10;
        window-padding-y = 5;
        unfocused-split-opacity = 1.0;
      }
      // lib.attrsets.optionalAttrs config.modules.neovim.enable {
        command = "direct:${lib.getExe (
          pkgs.writeShellScriptBin "nvim-with-login-shell-environment" ''
            exec "$SHELL" -lic 'exec ${lib.getExe config.neovim.package} +terminal'
          ''
        )}";
      }
      // lib.attrsets.optionalAttrs isLinux {
        mouse-scroll-multiplier = 1.25;
      }
      // (import ./colors.nix { inherit config; })
      // (import ./font.nix { inherit config lib isDarwin; });
    };

    modules.terminfo.entries.${terminfoEntry} =
      pkgs':
      if pkgs'.stdenv.isDarwin then
        pkgs'.runCommandLocal "ghostty-terminfo" { } ''
          cp -r "${pkgs'.brewCasks.ghostty}/Applications/Ghostty.app/Contents/Resources/terminfo/." "$out"
        ''
      else
        pkgs'.ghostty.terminfo;

    modules.terminals.ghostty = {
      enabled = true;
      inherit package;
      launchCommand =
        if isDarwin then
          "/usr/bin/open -na ${lib.escapeShellArg "${package}/Applications/Ghostty.app"} --args --working-directory=${config.home.homeDirectory}"
        else
          "${lib.getExe package} --working-directory=${config.home.homeDirectory}";
    };
  };
}
