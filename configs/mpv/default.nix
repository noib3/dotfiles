{ pkgs }:

{
  enable = pkgs.stdenv.isLinux;

  # See [1] for the full default config file containing all the possible
  # actions.
  bindings = {
    k = "cycle sub down";
  };
}

# [1]: https://raw.githubusercontent.com/mpv-player/mpv/master/etc/input.conf
