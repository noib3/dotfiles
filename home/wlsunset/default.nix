{ pkgs }:

{
  enable = pkgs.stdenv.isLinux;

  sunrise = "06:00";

  sunset = "22:00";

  temperature = {
    day = 6400;
    night = 3200;
  };
}
