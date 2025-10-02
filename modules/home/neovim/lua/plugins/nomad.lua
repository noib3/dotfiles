return {
  {
    dir = "~/Dropbox/dev/nomad/nomad",
    build = function()
      ---@type nomad.neovim.build
      local build = require("nomad.neovim.build")

      build.builders.cargo()
          :fallback(build.builders.download_prebuilt())
          :fallback(build.builders.nix())
          :build(build.contexts.lazy())
    end,
    opts = {
      collab = {
        server_address = "localhost:3000",
      },
    },
  }
}
