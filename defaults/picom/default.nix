{
  experimentalBackends = true;

  fade = true;
  fadeDelta = 3;

  shadow = true;
  shadowExclude = [
    "class_g = 'dmenu'"
  ];

  extraOptions = ''
    blur:
    {
      method = "gaussian";
      size = 2;
      deviation = 5.0;
    };
  '';
}
