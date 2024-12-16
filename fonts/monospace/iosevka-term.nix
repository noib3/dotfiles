{ pkgs, ... }:

{
  name = "IosevkaTerm Nerd Font";
  bold = "ExtraBold";
  bold_italic = "ExtraBold Italic";
  package = pkgs.nerd-fonts.iosevka-term;
  size = _config: _program: 16.5;
}
