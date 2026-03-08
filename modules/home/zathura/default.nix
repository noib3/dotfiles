{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.zathura;
  colors = import ./colors.nix { inherit config; };
in
{
  options.modules.zathura = {
    enable = mkEnableOption "Zathura";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isLinux;
        message = "Zathura is only available on Linux";
      }
    ];

    programs.zathura = {
      enable = true;

      options = {
        guioptions = "";
        selection-clipboard = "clipboard";
        highlight-transparency = "0.40";

        font =
          let
            font = config.fonts.serif;
            size = toString (font.size config "zathura");
          in
          "${font.name} ${size}";

        default-bg = colors.default.bg;
        default-fg = colors.default.fg;
        inputbar-bg = colors.inputbar.bg;
        inputbar-fg = colors.inputbar.fg;
        highlight-color = colors.highlight.bg;
      };
    };

    xdg.mimeApps.defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
    };
  };
}
