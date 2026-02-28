return {
  {
    "nomad/nomad",
    build = function()
      ---@type nomad.neovim.build
      local build = require("nomad.neovim.build")

      build.builders
        .download_prebuilt()
        :fallback(build.builders.nix())
        :fallback(build.builders.cargo())
        :build(build.contexts.lazy())
    end,
    opts = {
      -- collab = {
      --   server_address = "localhost:3000",
      -- }
    },
  },
}
