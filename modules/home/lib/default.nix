{
  config,
  lib,
  inputs,
  ...
}:

{
  config = {
    lib.mine = rec {
      # The absolute path to the root of this repository.
      dotfilesDir =
        if config.modules.dropbox.enable then
          "${config.home.homeDirectory}/Dropbox/dotfiles"
        else
          throw "Where are the dotfiles stored?";

      # Utility functions to work with colors in hex format.
      hex = import ./hex.nix { inherit lib; };

      # Transforms the given relative path to a file/directory in this
      # repository to an absolute path.
      mkAbsolute =
        path: dotfilesDir + lib.removePrefix (toString inputs.self) (toString path);

    };
  };
}
