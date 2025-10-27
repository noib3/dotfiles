{ pkgs, ... }:

{
  name = "IosevkaTerm Nerd Font";
  bold = "ExtraBold";
  bold_italic = "ExtraBold Italic";
  package = pkgs.nerd-fonts.iosevka-term;
  size =
    config: _program:
    if config.machines."skunk@darwin".isCurrent then
      22.75
    else if config.machines.stolen-bride.isCurrent then
      22.0
    else
      16.5;
}
