{ pkgs }:

''
  local M = {}

  M.bin = '${pkgs.sumneko-lua-language-server}/bin/lua-language-server'
  M.main = '${pkgs.sumneko-lua-language-server}/extras/main.lua'

  return M
''
