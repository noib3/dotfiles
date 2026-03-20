{ pkgs, ... }:

{
  modules.fonts.monospace.jetbrains-mono = {
    name = "JetBrainsMono Nerd Font";
    package = pkgs.nerd-fonts.jetbrains-mono;

    styles = {
      bold = "Extra Bold";
      boldItalic = "Extra Bold Italic";
    };

    sizes.default = 16.5;
  };
}
