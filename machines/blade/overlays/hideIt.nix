{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "hideIt";
  version = "master-2020-01-25";

  src = fetchFromGitHub {
    owner = "tadly";
    repo = "hideIt.sh";
    rev = "5b1180559ffaa53a5b5622960aaf7bbb178cce4a";
    sha256 = "15l2xg6c844vyfs5chfyigbvqdssqzcjfzrk2jgyw0r2vcbssj5y";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp -f $src/hideIt.sh $out/bin/hideIt.sh
    chmod 755 $out/bin/hideIt.sh
    patchShebangs $out/bin/hideIt.sh
  '';

  meta = with lib; {
    description = "Automagically hide/show a window by its name when the cursor is within a defined region or you mouse over it.";
    homepage = "https://github.com/tadly/hideIt.sh";
    licenses = licenses.gpl3;
    platforms = platforms.all;
    maintainers = [ maintainers.noib3 ];
  };
}
