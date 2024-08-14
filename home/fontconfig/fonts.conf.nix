{ config }:

let
  ff = config.fontFamily;
in
''
  <?xml version="1.0"?>
  <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  <fontconfig>
    <alias>
      <family>${ff.name}</family>
      <prefer>
        <family>${ff.name}</family>
        <family>Noto Color Emoji</family>
       </prefer>
    </alias>
  </fontconfig>
''
