let
  gmail = {
    folders = {
      inbox = "INBOX";
      sent = "[Gmail]/Sent Mail";
      trash = "[Gmail]/Trash";
    };
    imap = {
      host = "imap.gmail.com";
      port = 993;
    };
  };
in
{
  accounts = {
    # "main" = {
    #   primary = true;
    #   address = "riccardo.mazzarini@pm.me";
    #   realName = "Riccardo Mazzarini";
    #   userName = "riccardo.mazzarini@pm.me";
    #   # imap.host = "test";
    #   # smtp.host = "test";
    #   # passwordCommand = "test";
    #   neomutt.enable = true;
    # };

    "garbage" = {
      primary = true;
      flavor = "gmail.com";
      address = "riccardo.mazzarini98@gmail.com";
      realName = "Riccardo Mazzarini";
      passwordCommand = "pass gmail@riccardo.mazzarini98";
      folders = gmail.folders;
      imap = gmail.imap;
      neomutt = {
        enable = true;
        extraConfig = ''
          set folder = "imaps://${gmail.imap.host}:${builtins.toString gmail.imap.port}/"
          set spoolfile = "+${gmail.folders.inbox}"
          set imap_user = "riccardo.mazzarini98@gmail.com"
          set imap_pass = `pass gmail@riccardo.mazzarini98`
        '';
      };
    };
  };
}
