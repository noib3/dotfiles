{
  inputs,
  fonts,
  colorscheme,
  username,
}:

let
  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      config = {
        allowUnfreePredicate =
          pkg:
          builtins.elem (inputs.nixpkgs.lib.getName pkg) [
            "megasync"
            "ookla-speedtest"
            "spotify"
            "zoom"
          ];
      };
      overlays = [
        inputs.brew-nix.overlays.default
        inputs.neovim-nightly-overlay.overlays.default
        inputs.nur.overlay
        inputs.rust-overlay.overlays.default
        (final: prev: {
          scripts = import ../scripts {
            inherit colorscheme;
            pkgs = prev;
          };
        })
      ];
    };

  mkNixosConfiguration =
    { system, modules }:
    inputs.nixpkgs.lib.nixosSystem rec {
      inherit system modules;
      pkgs = mkPkgs system;
      specialArgs = {
        inherit username;
      };
    };

  mkHomeConfiguration =
    { system }:
    inputs.home-manager.lib.homeManagerConfiguration rec {
      pkgs = mkPkgs system;

      modules =
        [
          inputs.ags.homeManagerModules.default
          ../fonts/module.nix
          ../home.nix
          ../modules/programs/vivid.nix
          ../modules/services/bluetooth-autoconnect.nix
          ../modules/services/skhd.nix
        ]
        ++ pkgs.lib.lists.optionals pkgs.stdenv.isDarwin [
          #
          inputs.mac-app-util.homeManagerModules.default
        ];

      extraSpecialArgs = {
        inherit colorscheme username;
        fonts = (fonts pkgs);
      };
    };
in
{
  skunk =
    let
      name = "skunk";
      system = "x86_64-darwin";
    in
    {
      nixosConfiguration = mkNixosConfiguration {
        inherit system;
        modules = [
          ./skunk/configuration.nix
          ../modules/block-domains.nix
          inputs.nixos-hardware.nixosModules.apple-t2
        ];
      };

      darwinConfiguration = inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          machine = name;
        };
        modules = [ ./skunk/darwin-configuration.nix ];
      };

      homeConfiguration = mkHomeConfiguration { inherit system; };
    };
}
