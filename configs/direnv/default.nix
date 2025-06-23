{
  enable = true;

  config = {
    global = {
      disable_stdin = true;
      warn_timeout = "5m";
    };
  };

  nix-direnv.enable = true;
}
