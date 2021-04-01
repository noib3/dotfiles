{
  shellAliases = {
    reboot = "sudo shutdown -r now";
    shutdown = "sudo shutdown now";
    xclip = "xclip -selection c";
    lf = "~/Sync/dotfiles/machines/blade/overrides/lf/launcher";
    # lf = ../lf/launcher;
  };

  shellAbbrs = {
    nrs = "sudo nixos-rebuild switch";
  };
}
