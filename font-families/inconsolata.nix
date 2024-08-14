# { lib, config }:

{
  name = "Inconsolata Nerd Font";
  nerdfontsName = "Inconsolata";
  # size = 16;

  # alacritty = {
  #   size = lib.mkIf config.machine.skunk.isCurrent 16.5;
  # };

  size = 16.5;
}
