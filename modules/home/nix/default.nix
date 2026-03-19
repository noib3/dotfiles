{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.nix-jettison.homeManagerModules.default
  ];

  config = {
    home.packages = with pkgs; [
      nixVersions.latest
      nixd
      nixfmt
    ];

    nix = {
      package = pkgs.nixVersions.latest;
      plugins.jettison.enable = false;
      settings = {
        experimental-features = [
          "flakes"
          "nix-command"
          "pipe-operators"
        ];
        use-xdg-base-directories = true;
        warn-dirty = false;
      };
    };

    # Make `nix develop` and `nix shell` use fish instead of bash.
    programs.fish.interactiveShellInit = lib.mkIf config.programs.fish.enable ''
      function nix --description "Reproducible and declarative configuration management"
          ${pkgs.nix-your-shell}/bin/nix-your-shell fish nix -- $argv
      end
    '';

    programs.nix-index.enable = true;
  };
}
