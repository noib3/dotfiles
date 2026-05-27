{ config, pkgs, ... }:

{
  modules.fonts.monospace.iosevka-term = {
    name = "IosevkaTerm Nerd Font";
    package = pkgs.nerd-fonts.iosevka-term;

    styles = {
      bold = "ExtraBold";
      boldItalic = "ExtraBold Italic";
    };

    sizes = {
      default =
        {
          "skunk@macos" = 22.75;
          stolen-bride = 22.0;
        }
        .${config.machines.current.name} or 16.5;
    };
  };
}
