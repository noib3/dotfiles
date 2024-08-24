{ pkgs, ... }:

{
  name = "FiraSans";
  package = pkgs.fira-sans;
  size = _config: _program: 14.5;
}
