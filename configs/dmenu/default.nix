{ font, colors }:

let
  pkgs = import <nixpkgs> { };

  patches = {
    caseinsensitive = ./patches/dmenu-caseinsensitive-20200523-db6093f.diff;
    colorprompt = ./patches/dmenu-colorprompt.diff;
    fuzzyhighlight = ./patches/dmenu-fuzzyhighlight-4.9.diff;
    fuzzymatch = ./patches/dmenu-fuzzymatch-4.9.diff;
    lineheight = ./patches/dmenu-lineheight-5.0.diff;
    listfullwidth = ./patches/dmenu-listfullwidth-5.0.diff;
    numbers = ./patches/dmenu-numbers-4.9.diff;
    password = ./patches/dmenu-password-5.0.diff;
    preselect = ./patches/dmenu-preselect-20200513-db6093f.diff;
    tsv = ./patches/dmenu-tsv-20201101-1a13d04.diff;
    fontcolors = pkgs.writeText "dmenu-fontcolors.diff"
      (import ./patches/dmenu-fontcolors.diff.nix { inherit font colors; });
  };
in
pkgs.dmenu.override ({
  patches = [
    patches.caseinsensitive
    patches.fuzzyhighlight
    patches.fuzzymatch
    patches.listfullwidth
    patches.numbers
    patches.password
    patches.preselect
    patches.tsv
    patches.lineheight
    patches.colorprompt
    patches.fontcolors
  ];
})
