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
        if config.machines."skunk@darwin".isCurrent then
          22.75
        else if config.machines.stolen-bride.isCurrent then
          22.0
        else
          16.5;
    };
  };
}
