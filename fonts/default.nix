rec {
  emoji = {
    noto-color = import ./emoji/noto-color.nix;
  };

  monospace = {
    fira-code = import ./monospace/fira-code.nix;
    inconsolata = import ./monospace/inconsolata.nix;
    iosevka = import ./monospace/iosevka.nix;
    jetbrains-mono = import ./monospace/jetbrains-mono.nix;
    source-code-pro = import ./monospace/source-code-pro.nix;
  };

  sansSerif = {
    fira-sans = import ./sans-serif/fira-sans.nix;
  };

  schemes = {
    fira =
      pkgs:
      let
        fira-sans = sansSerif.fira-sans { inherit pkgs; };
      in
      {
        sansSerif = fira-sans;
        serif = fira-sans;
        monospace = monospace.fira-code { inherit pkgs; };
        emoji = emoji.noto-color { inherit pkgs; };
      };
  };
}
