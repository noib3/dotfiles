{
  blur = true;
  experimentalBackends = true;

  opacityRule = [
    "90:class_i ?= 'fuzzy-opener'"
  ];

  fade = true;
  fadeDelta = 3;

  extraOptions = ''
    blur:
    {
      method = "gaussian";
      size = 10;
      deviation = 5.0;
    };
  '';
}
