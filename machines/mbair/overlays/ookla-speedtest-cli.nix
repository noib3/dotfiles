{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "ookla-speedtest-cli";
  version = "1.0.0";

  src = fetchurl {
    url = "https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-${version}-macosx.tgz";
    sha256 = "1x78lmq6nkkd745cvgczgs3k2qcp2qq1fvv7nw2bz3v63slgh2ld";
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
    platforms = platforms.darwin;
  };
}
