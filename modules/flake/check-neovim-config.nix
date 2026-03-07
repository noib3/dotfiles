{
  inputs,
  ...
}:

{
  perSystem =
    { pkgs, system, ... }:
    {
      checks.neovim-config =
        pkgs.runCommand "check-neovim-config"
          {
            nativeBuildInputs = [ pkgs.lua-language-server ];
            env.VIMRUNTIME = inputs.neovim.vimRuntime.${system};
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
