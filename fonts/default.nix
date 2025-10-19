let
  fonts = {
    emoji = import ./emoji;
    monospace = import ./monospace;
    sansSerif = import ./sans-serif;
    serif = import ./serif;
  };
in
{
  blex = pkgs: rec {
    sansSerif = monospace;
    serif = monospace;
    monospace = fonts.monospace.blex-mono { inherit pkgs; };
    emoji = fonts.emoji.noto-color { inherit pkgs; };
  };

  docsrs = pkgs: {
    sansSerif = fonts.sansSerif.fira-sans { inherit pkgs; };
    serif = fonts.serif.source-serif { inherit pkgs; };
    monospace = fonts.monospace.source-code-pro { inherit pkgs; };
    emoji = fonts.emoji.noto-color { inherit pkgs; };
  };

  fira = pkgs: rec {
    sansSerif = fonts.sansSerif.fira-sans { inherit pkgs; };
    serif = sansSerif;
    monospace = fonts.monospace.fira-code { inherit pkgs; };
    emoji = fonts.emoji.noto-color { inherit pkgs; };
  };

  iosevka = pkgs: rec {
    sansSerif = fonts.sansSerif.iosevka-aile { inherit pkgs; };
    serif = sansSerif;
    monospace = fonts.monospace.iosevka-term { inherit pkgs; };
    emoji = fonts.emoji.noto-color { inherit pkgs; };
  };
}
