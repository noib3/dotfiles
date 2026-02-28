{
  inputs,
  ...
}:

{
  perSystem =
    { pkgs, system, ... }:
    let
      neovim = inputs.nix-community-neovim.packages.${system}.default;
    in
    {
      checks.neovim-config =
        pkgs.runCommand "check-neovim-config"
          {
            nativeBuildInputs = [ pkgs.lua-language-server ];
            env.VIMRUNTIME = "${neovim}/share/nvim/runtime";
          }
          ''
            lua-language-server \
              --check ${../home/neovim} \
              --logpath="$TMPDIR" \
              --metapath="$TMPDIR/meta" \
              2>&1 | tee "$out"
          '';
    };
}
