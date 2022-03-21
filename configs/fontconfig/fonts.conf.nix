{ fontFamily }:

''
  <?xml version="1.0"?>
  <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  <fontconfig>
    <alias>
      <family>${fontFamily}</family>
      <prefer>
        <family>${fontFamily}</family>
        <family>Noto Color Emoji</family>
       </prefer>
    </alias>
  </fontconfig>
''
