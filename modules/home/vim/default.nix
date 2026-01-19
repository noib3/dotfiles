{
  config,
  ...
}:

{
  config = {
    xdg.configFile."vim/vimrc".text = ''
      set viminfofile=${config.xdg.stateHome}/vim/viminfo
    '';
  };
}
