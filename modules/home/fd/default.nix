{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.fd;
in
{
  options.modules.fd = {
    enable = mkEnableOption "fd";
  };

  config = mkIf cfg.enable {
    programs.fd = {
      enable = true;

      ignores = [
        "**/.cache"
        "**/.direnv"
        "**/.dropbox"
        "**/.dropbox.cache"
        "**/.git"
        "**/.ipython"
        "**/.stfolder"
        "**/gnupg/*"
        "**/target"
        "*.aux"
        "*.bbl"
        "*.bcf"
        "*.blg"
        "*.dropbox"
        "*.loe"
        "*.log"
        "*.out"
        "*.run.xml"
        "*.synctex(busy)"
        "*.synctex.gz"
        "*.toc"
      ]
      ++ lib.lists.optionals pkgs.stdenv.isDarwin [
        "/.Trash"
        "/Applications"
        "/Library"
        "/Music"
        "/Pictures"
      ];
    };
  };
}
