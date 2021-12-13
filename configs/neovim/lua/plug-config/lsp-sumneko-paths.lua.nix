let
  pkgs = import <nixpkgs> { };
in
''
  return {
    bin = '${pkgs.sumneko-lua-language-server}/bin/lua-language-server',
    main = '${pkgs.sumneko-lua-language-server}/extras/main.lua',
  }
''
