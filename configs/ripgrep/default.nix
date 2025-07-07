{
  enable = true;

  arguments = [
    "--smart-case"
    "--no-heading"
    "--hidden"
    "--iglob=!LICENSE"
    "--glob=!**/.git/**"
    "--glob=!**/.cache/**"
  ];
}
