{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "ookla-speedtest-cli";
  version = "1.0.0";

  src = fetchurl {
    url = "https://install.speedtest.net/app/cli/ookla-speedtest-${version}-x86_64-linux.tgz";
    sha256 = "0s1icdqdkr1g4dsnsqvh1a4vp4b61vvrr7qx4gsf89s41n7h5qjz";
  };

  # Work around the "unpacker appears to have produced no directories" case
  # that happens when the archive doesn't have a subdirectory.
  sourceRoot = ".";

  unpackPahse = ''
    tar -xzf $src
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp speedtest $out/bin
  '';

  meta = with lib; {
    description = "Speedtest application by Ookla";
    homepage = "https://www.speedtest.net/apps/cli";
    maintainers = [ maintainers.noib3 ];
    platforms = [ "x86_64-linux" ];
  };
}
