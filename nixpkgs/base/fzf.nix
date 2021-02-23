{
  defaultCommand = "fd --base-directory=$HOME --hidden --type=f --color=always";
  defaultOptions = [
    "--reverse"
    "--no-bold"
    "--info=inline"
    "--hscroll-off=50"
    "--ansi"
    "--color='hl:-1:underline'"
    "--color='fg+:-1:regular:italic'"
    "--color='hl+:-1:underline:italic'"
    "--color='prompt:4:regular'"
    "--color='pointer:1'"
  ];
}
