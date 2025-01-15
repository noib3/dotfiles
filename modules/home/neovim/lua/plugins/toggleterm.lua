local utils = require("utils")

local setup_lazygit = function()
  local Terminal = require("toggleterm.terminal").Terminal
  local lazygit = Terminal:new({
    cmd = "lazygit",
    dir = "git_dir",
    hidden = true,
  })
  vim.keymap.set("n", "lg", function() lazygit:toggle() end, { silent = true })
end

local setup_lf = function()
  local Terminal = require("toggleterm.terminal").Terminal

  -- A file to write the selected files and dirs to on exit.
  local temp_file = os.tmpname()

  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function() os.remove(temp_file) end
  })

  local cmd = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    local buf_path = vim.uv.fs_stat(buf_name) and buf_name or ""
    return ("lf -selection-path %s %s"):format(temp_file, buf_path)
  end

  -- The focused window at the time lf was opened.
  ---@type integer|nil
  local window = nil

  local lf = Terminal:new({
    hidden = true,
    on_exit = function()
      if not temp_file then return end
      local selected_paths = utils.fs.read_file(temp_file)
      if not selected_paths then return end
      -- TODO:
      -- * ignore directories;
      -- * if file is not text file, shell out to `open`;
      -- * if text file is currently focused, skip it;
      -- * if text file is first one, open it in current window;
      -- * if text file is not first one, add it to the qf list;
      for path in utils.lua.iter_lines(selected_paths) do
        ---@cast window integer
        vim.api.nvim_win_call(window, function()
          vim.cmd.edit(vim.fn.fnameescape(path))
        end)
      end
    end
  })

  local open_lf = function()
    window = vim.api.nvim_get_current_win()
    lf.cmd = cmd()
    lf:toggle()
  end

  vim.keymap.set("n", "ll", open_lf, { silent = true })
end

return {
  {
    "akinsho/toggleterm.nvim",
    opts = {
      autochdir = true,
      direction = "float",
      float_opts = {
        border = "single",
        height = function() return utils.math.round(vim.o.lines * 0.8) end,
        width = function() return utils.math.round(vim.o.columns * 0.8) end,
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
      setup_lazygit()
      setup_lf()
    end
  }
}
