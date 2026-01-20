{
  config,
  lib,
  inputs,
  ...
}:

{
  config.lib.mine = rec {
    base64Encode = import ./base64-encode.nix lib;

    # The absolute path to the root of this repository.
    documentsDir =
      if config.modules.dropbox.enable then
        config.modules.dropbox.directory
      else if config.modules.proton-drive.enable then
        config.modules.proton-drive.directory
      else
        throw "Where are the documents stored?";

    # The absolute path to the root of this repository.
    dotfilesDir = "${documentsDir}/dotfiles";

    # Utility functions to work with colors in hex format.
    hex = import ./hex.nix { inherit lib; };

    # Transforms the given relative path to a file/directory in this
    # repository to an absolute path.
    mkAbsolute =
      path: dotfilesDir + lib.removePrefix (toString inputs.self) (toString path);
  };
}
