let
  pkgs = import <nixpkgs> { };

  buildFirefoxXpiAddon = { pname, version, addonId, url, sha256, meta, ... }:
    pkgs.stdenv.mkDerivation {
      name = "${pname}-${version}";

      inherit meta;

      src = pkgs.fetchurl { inherit url sha256; };

      preferLocalBuild = true;
      allowSubstitutes = false;

      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    };
in
{
  bitwarden = buildFirefoxXpiAddon {
    pname = "bitwarden";
    version = "1.48.1";
    addonId = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
    url = "https://addons.mozilla.org/firefox/downloads/file/3714988/bitwarden_free_password_manager-1.48.1-an+fx.xpi";
    sha256 = "27088233b72c36f8636ae88e79d7e52a0b4480d7fc73ed6412233a2f95408256";
    meta = with pkgs.lib; {
      homepage = "https://bitwarden.com";
      description = "A secure and free password manager for all of your devices.";
      license = licenses.gpl3;
      platforms = platforms.all;
    };
  };

  tridactyl-no-new-tab = buildFirefoxXpiAddon {
    pname = "tridactyl";
    version = "1.21.0";
    addonId = "tridactyl.vim.betas.nonewtab@cmcaine.co.uk";
    url = "https://tridactyl.cmcaine.co.uk/betas/nonewtab/tridactyl_no_new_tab_beta-latest.xpi";
    sha256 = "1w5qqjy66qbp1f7fkqlbgb9s18a4cbk7g53g0vfq2815nnm1zv5x";
    meta = with pkgs.lib; {
      homepage = "https://github.com/cmcaine/tridactyl";
      description = ''
        Vim, but in your browser. Replace Firefox's control mechanism with one
        modelled on Vim.

        This addon is very usable, but is in an early stage of development.
        We intend to implement the majority of Vimperator's features.
      '';
      license = licenses.asl20;
      platforms = platforms.all;
    };
  };
}
