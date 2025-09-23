{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    home.packages = with pkgs; [
      nixd
      nixVersions.latest
      nixfmt-rfc-style
    ];

    nix = {
      package = pkgs.nixVersions.latest;
      settings = {
        experimental-features = [
          "flakes"
          "nix-command"
          "pipe-operators"
        ];
        trusted-substituters = [
          "https://nix-community.cachix.org"
        ]
        ++ (lib.optional config.machines."skunk@linux".isCurrent "https://cache.soopy.moe");
        warn-dirty = false;
      };
    };

    # Make `nix develop`, `nix shell` and `nix-shell` use fish instead of bash.
    programs.fish.interactiveShellInit = lib.mkIf config.programs.fish.enable ''
      function nix-shell --description "Start an interactive shell based on a Nix expression"
          ${pkgs.nix-your-shell}/bin/nix-your-shell fish nix-shell -- $argv
      end

      function nix --description "Reproducible and declarative configuration management"
          ${pkgs.nix-your-shell}/bin/nix-your-shell fish nix -- $argv
      end
    '';
  };
}
