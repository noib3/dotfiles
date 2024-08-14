{
  homeManagerModule = import ./module.nix;

  iosevka = import ./iosevka.nix;
  firacode = import ./firacode.nix;
  inconsolata = import ./inconsolata.nix;
  jetbrains-mono = import ./jetbrains-mono.nix;
  source-code-pro = import ./source-code-pro.nix;
}
