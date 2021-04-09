{ pkgs, font, colors }:

{
  # theme = "${pkgs.rofi}/share/rofi/themes/android_notification";

  font = "${font.family} ${font.style} ${font.size}";
  scrollbar = false;
  cycle = false;

  padding = 300;
  terminal = "${pkgs.alacritty}/bin/alacritty";
  fullscreen = true;

  colors = {
    window = {
      background = "#282c34";
      border = "argb:582a373e";
      separator = "#c3c6c8";
    };

    rows = {
      normal = {
        background = "argb:58455a64";
        foreground = "#fafbfc";
        backgroundAlt = "argb:58455a64";
        highlight = {
          background = "#00bcd4";
          foreground = "#fafbfc";
        };
      };
    };
  };

  # theme =
  #   let
  #     inherit (pkgs.config.lib.formats.rasi) mkLiteral;
  #   in
  #   {
  #     "*" = {
  #       background-color = mkLiteral "#282c34";
  #     };
  #   };

  # extraConfig = {
  #   show-icons = true;
  # };

  #extraConfig = ''
  #  #window {
  #    background-color: rgba( 0, 0, 255, 100% );
  #  }
  #'';
}
