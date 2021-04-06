{ colors }:

{
  defaultCommand = ''
    fd --base-directory=$HOME --hidden --type=f --color=always \
      | sed 's/\x1b\[${colors.dir}m/\x1b\[${colors.fgod}m/g'
  '';

  defaultOptions = [
    "--reverse"
    "--no-bold"
    "--info=inline"
    "--height=8"
    "--hscroll-off=50"
    "--ansi"
    "--preview-window=sharp"
    "--color='hl:-1:underline'"
    "--color='fg+:-1:regular:italic'"
    "--color='hl+:-1:underline:italic'"
    "--color='prompt:4:regular'"
    "--color='pointer:1'"
    "--color='bg+:${colors.bgplus}'"
    "--color='border:${colors.border}'"
  ];

  changeDirWidgetCommand = ''
    fd --base-directory=$HOME --hidden --type=d --color=always \
      | sed 's/\x1b\[${colors.dir}m/\x1b\[${colors.fgod}m/g' \
      | sed 's/\(.*\)\x1b\[${colors.fgod}m/\1\x1b\[${colors.dir}m/'
  '';

  changeDirWidgetOptions = [
    "--prompt='Cd> '"
    "--preview='ls --color=always ~/{}'"
  ];

  enableFishIntegration = true;
}
