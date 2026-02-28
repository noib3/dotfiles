{
  inputs,
  ...
}:

{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { config, ... }:
    {
      checks.format = config.treefmt.build.check inputs.self;

      formatter = config.treefmt.build.wrapper;

      treefmt = {
        # We've already added a 'format' check.
        flakeCheck = false;
        projectRootFile = "flake.nix";
        programs.nixfmt = {
          enable = true;
          width = 80;
        };
        programs.stylua = {
          enable = true;
          settings = builtins.fromTOML (builtins.readFile ../../stylua.toml);
        };
      };
    };
}
