return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
      {
        "mrcjkb/rustaceanvim",
        init = function()
          vim.g.rustaceanvim = { server = { auto_attach = false } }
        end,
      },
    },
    config = function()
      local neotest = require("neotest")
      local palette = require("generated.palette")

      neotest.setup({
        adapters = {
          require("rustaceanvim.neotest"),
        },
        status = {
          signs = false,
          virtual_text = true,
        },
      })

      vim.keymap.set("n", "<D-c><D-c>", neotest.run.run, {
        desc = "Run the test nearest to the current cursor position",
      })

      vim.keymap.set("n", "<D-c>l", neotest.run.run_last, {
        desc = "Re-run the last test",
      })

      local set_neotest_colors = function()
        vim.api.nvim_set_hl(0, "NeotestPassed", { fg = palette.bright.green })
        vim.api.nvim_set_hl(0, "NeotestFailed", { fg = palette.bright.red })
        vim.api.nvim_set_hl(0, "NeotestRunning", { fg = palette.bright.blue })
        vim.api.nvim_set_hl(0, "NeotestSkipped", { link = "Comment" })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = set_neotest_colors,
      })

      -- The ColorScheme event might've already fired, so also run the callback
      -- on startup.
      set_neotest_colors()

      -- TODO:
      --
      -- 1. when the cursor is on a line where a test is running, provide a
      -- code action to stop that test;
      --
      -- 2. when the cursor is *not* on a test line but *is* in a buffer with
      -- at least one test running, provide a code action to stop all pending
      -- tests in that buffer;
    end,
  },
}
