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
        programs.nixfmt.enable = true;
        programs.stylua.enable = true;
      };
    };
}
