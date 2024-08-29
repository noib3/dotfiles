{
  inputs,
  fonts,
  colorscheme,
  userName,
}@opts:

let
  machineSources = [
    (import ./skunk).linux
    (import ./skunk).darwin
  ];

  inherit (inputs.nixpkgs) lib;

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

  # A home-manager module that defines `config.machine(s)`.
  mkHomeManagerModule =
    targetMachine:
    { config, ... }:
    # {
    #   config.machine = targetMachine // {
    #     hasNixosConfiguration = targetMachine ? nixosConfiguration;
    #     hasDarwinConfiguration = targetMachine ? darwinConfiguration;
    #   };
    #   config.machines = builtins.listToAttrs (
    #     map (machine: {
    #       name = machine.name;
    #       value = {
    #         enable = machine.name == targetMachine.name;
    #       };
    #     }) machines
    #   );
    # };
    {
    };

  mkHomeConfiguration =
    machine:
    inputs.home-manager.lib.homeManagerConfiguration rec {
      pkgs = mkPkgs machine.system;

      modules =
        [
          inputs.ags.homeManagerModules.default
          ../fonts/module.nix
          ../home.nix
          ../modules/programs/vivid.nix
          ../modules/services/bluetooth-autoconnect.nix
          ../modules/services/skhd.nix
          (mkHomeManagerModule machine)
        ]
        ++ lib.lists.optionals pkgs.stdenv.isDarwin [
          #
          inputs.mac-app-util.homeManagerModules.default
        ];

      extraSpecialArgs = {
        inherit colorscheme userName;
        fonts = (fonts pkgs);
      };
    };

  machines = map (
    m:
    let
      machine = m opts;
      pkgs = mkPkgs machine;
    in
    {
      name = machine.name;
      nixosConfiguration = machine.nixosConfiguration pkgs;
      darwinConfiguration = machine.darwinConfiguration pkgs;
      homeConfiguration = mkHomeConfiguration machine;
    }
  ) machineSources;
in
{
  forEach = forMachine: (lib.lists.foldl' lib.attrsets.recursiveUpdate { } (map forMachine machines));

  /*
    machines = [
      skunk.linux
      skunk.darwin
    ];

    =>

    machines = [
      {
        name = "skunk@linux";
        nixosConfiguration = {};
      }
      {
        name = "skunk@darwin";
        nixosConfiguration = {};
      }
    ];

    =>

    machines = [
      {
        nixosConfigurations."skunk@linux" = {};
      }
      {
        nixosConfigurations."skunk@darwin" = {};
      }
    ];

    machines = [
      {
        name = "skunk@linux";
        value = {
          name = "skunk@linux";
          nixosConfiguration = {};
        };
      {
        name = "skunk@darwin";
        value = {
          name = "skunk@darwin";
          nixosConfiguration = {};
        };
      }
      }
    ];
  */
}
