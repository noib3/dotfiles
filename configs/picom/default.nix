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
      size = 20;
      deviation = 10.0;
    };
  '';
}
