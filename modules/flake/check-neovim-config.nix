{
  inputs,
  ...
}:

{
  perSystem =
    { system, ... }:
    {
      checks.neovim-config = inputs.neovim.checks.${system}.default;
    };
}
