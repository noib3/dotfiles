-- TODO: create a PR to add to Neovim

local api = vim.api

local M = {}

---@param buf integer
---@param cursor {[1]: integer, [2]: integer}
---@param term_keys editable_term.TermKeys
local function set_term_cursor(buf, cursor, term_keys)
  local bufinfo = M.buffers[buf]
  local cmd_start = bufinfo.cmd_cursor
  if not cmd_start then return end
  if cursor[1] < cmd_start[1] then return end
  local n_forward_chars ---@type integer
  if cursor[1] == cmd_start[1] then
    local line = api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], true)[1]
    local cursor_end_index = vim.str_utfindex(line, "utf-32", cursor[2], true)
    n_forward_chars = cursor_end_index - cmd_start[2]
  else
    local lines = api.nvim_buf_get_lines(buf, cmd_start[1] - 1, cursor[1], true)

    for i, line in ipairs(lines) do
      if line ~= "" then
        if i == 1 then
          local first_line_end_index =
            vim.str_utfindex(line, "utf-32", #line - 1, true)
          n_forward_chars = first_line_end_index - cmd_start[2] + 1
        elseif i == #lines then
          local last_line_end_index =
            vim.str_utfindex(line, "utf-32", cursor[2], true)
          n_forward_chars = n_forward_chars + last_line_end_index
        else
          local end_index = vim.str_utfindex(line, "utf-32", #line - 1, true)
          n_forward_chars = n_forward_chars + end_index + 1
        end
      end
    end
  end

  local movement_chars = vim.keycode(term_keys.goto_line_start)
    .. vim.keycode(term_keys.forward_char):rep(n_forward_chars)
  vim.fn.chansend(vim.bo.channel, movement_chars)
end

---@param buf integer
---@param new_lines string[]
---@param term_keys editable_term.TermKeys
local function update_lines(buf, new_lines, term_keys)
  local bufinfo = M.buffers[buf]
  local cmd_start = bufinfo.cmd_cursor
  if not cmd_start then return end

  local new_term_line_segments = {} ---@type string[]
  for i, line in ipairs(new_lines) do
    if line ~= "" then
      if i == 1 then
        local cmd_start_byte_index =
          vim.str_byteindex(line, "utf-32", cmd_start[2])
        table.insert(new_term_line_segments, line:sub(cmd_start_byte_index + 1))
      else
        table.insert(new_term_line_segments, line)
      end
    end
  end
  local new_term_line = table.concat(new_term_line_segments)

  vim.fn.chansend(
    vim.bo[buf].channel,
    vim.keycode(term_keys.clear_current_line)
      .. new_term_line
      .. vim.keycode(term_keys.clear_suggestions)
  )
end

---@class editable_term.TermKeys
---@field clear_current_line string
---@field forward_char string
---@field goto_line_start string
---@field goto_line_end string
---@field clear_suggestions string

---@class editable_term.Config
---@field term_keys? editable_term.TermKeys

---@class editable_term.BufInfo
---@field cmd_cursor? {[1]: integer, [2]: integer}

---@type {[integer]: editable_term.BufInfo}
M.buffers = {}

---@param config editable_term.Config?
M.setup = function(config)
  config = config or {}

  local term_keys = config.term_keys
    or {
      goto_line_start = "<c-a>",
      goto_line_end = "<c-e>",
      clear_current_line = "<c-u>",
      forward_char = "<c-f>",
      clear_suggestions = "",
    }

  api.nvim_create_autocmd("TermOpen", {
    group = api.nvim_create_augroup("editable-term", { clear = true }),
    callback = function(args)
      local editgroup = api.nvim_create_augroup(
        "editable-term-text-change" .. args.buf,
        { clear = true }
      )
      M.buffers[args.buf] = {}

      vim.keymap.set("n", "A", function()
        vim.fn.chansend(vim.bo.channel, vim.keycode(term_keys.goto_line_end))
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set("n", "I", function()
        vim.fn.chansend(vim.bo.channel, vim.keycode(term_keys.goto_line_start))
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set("n", "i", function()
        local bufinfo = M.buffers[args.buf]
        local cursor = api.nvim_win_get_cursor(0)
        if bufinfo.cmd_cursor and cursor[1] >= bufinfo.cmd_cursor[1] then
          set_term_cursor(args.buf, cursor, term_keys)
        else
          vim.fn.chansend(vim.bo.channel, vim.keycode(term_keys.goto_line_end))
        end
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set("n", "a", function()
        local bufinfo = M.buffers[args.buf]
        local cursor = api.nvim_win_get_cursor(0)
        if bufinfo.cmd_cursor and cursor[1] >= bufinfo.cmd_cursor[1] then
          cursor[2] = cursor[2] + 1
          set_term_cursor(args.buf, cursor, term_keys)
        else
          vim.fn.chansend(vim.bo.channel, vim.keycode(term_keys.goto_line_end))
        end
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set(
        "n",
        "dd",
        function()
          vim.fn.chansend(
            vim.bo.channel,
            vim.keycode(
              term_keys.clear_current_line .. term_keys.goto_line_start
            )
          )
        end,
        { buffer = args.buf }
      )

      vim.keymap.set("n", "cc", function()
        vim.fn.chansend(
          vim.bo.channel,
          vim.keycode(term_keys.clear_current_line .. term_keys.goto_line_start)
        )
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      -- NOTE: does not work with empty regions (e.g. `ci"` with the text `grep
      -- ""`) because the marks `[` and `]` return {0, 0}. TextYankPost can be
      -- used to compute the change ourselves and make this work with empty
      -- regions, but it wouldn't work when using the blackhole register.
      -- NOTE: the problem with empty ranges includes plugins workarounds like
      -- on mini.ai or targets.vim, but for a different reason. Their
      -- workaround is to insert a single space in the empty region, visually
      -- select it and allow only operators like `c` or `d` (because they'll be
      -- able to delete the space)
      api.nvim_create_autocmd("ModeChanged", {
        group = editgroup,
        buffer = args.buf,
        callback = function(args2)
          local intercepting_c_operator = (
            vim.v.event.old_mode == "v" or vim.v.event.old_mode == "no"
          )
            and vim.v.event.new_mode == "t"
            and vim.v.operator == "c"
          local intercepting_d_or_custom_operator = (
            (vim.v.event.old_mode == "v" or vim.v.event.old_mode == "no")
            and vim.v.event.new_mode == "nt"
            and (vim.v.operator == "d" or vim.v.operator == "g@")
          )
          if
            not intercepting_c_operator
            and not intercepting_d_or_custom_operator
          then
            return
          end

          local bufinfo = M.buffers[args2.buf]
          local cmd_start = bufinfo.cmd_cursor
          if not cmd_start then return end

          local start_point = api.nvim_buf_get_mark(args2.buf, "[")
          local end_point = api.nvim_buf_get_mark(args2.buf, "]")

          -- NOTE: this seems to happen when trying to change an empty region
          -- in a terminal buffer. For now, treat this as invalid
          if
            start_point[1] == 0
            and start_point[2] == 0
            and end_point[1] == 0
            and end_point[2] == 0
          then
            vim.fn.chansend(vim.bo.channel, vim.keycode("<c-c>"))
            return
          end

          -- TODO: use vim.range here and everywhere when creating a PR to Neovim
          if
            start_point[1] < cmd_start[1]
            or end_point[1] < cmd_start[1]
            or (start_point[1] == cmd_start[1] and start_point[2] < cmd_start[2])
            or (end_point[1] == cmd_start[1] and end_point[2] < cmd_start[2])
          then
            vim.fn.chansend(vim.bo.channel, vim.keycode("<c-c>"))
            return
          end

          -- TODO: check if custom operators that end in terminal mode trigger TextChanged
          -- NOTE: operators that do not end in terminal mode are captured by TextChanged
          if vim.v.event.new_mode ~= "t" then return end

          local lines =
            api.nvim_buf_get_lines(args2.buf, cmd_start[1] - 1, -1, true)
          local new_lines = {} ---@type string[]
          for i, line in ipairs(lines) do
            table.insert(new_lines, line)
            local is_last_new_line = lines[i + 1] == "" and lines[i + 2] == ""
            if is_last_new_line then break end
          end

          update_lines(args2.buf, new_lines, term_keys)

          -- NOTE: this is an empty region
          if
            start_point[1] == end_point[1] and end_point[2] < start_point[2]
          then
            start_point[2] = start_point[2] - 1
          end
          set_term_cursor(args2.buf, start_point, term_keys)
        end,
      })

      -- NOTE: the event gets retriggered by the changes made on `update_line`,
      -- so we need to ignore it for a small amount of time
      -- NOTE: the event gets triggered on terminal reflow, which may happen
      -- when opening a new window on a split or even on `q:`
      local busy = false
      api.nvim_create_autocmd("TextChanged", {
        buffer = args.buf,
        group = editgroup,
        callback = function(args2)
          local bufinfo = M.buffers[args2.buf]
          local cmd_start = bufinfo.cmd_cursor
          if not cmd_start then return end

          if api.nvim_get_current_buf() ~= args2.buf then return end

          local mode = api.nvim_get_mode().mode
          if mode ~= "n" and mode ~= "nt" then return end

          if busy then return end
          busy = true
          vim.defer_fn(function()
            busy = false
            -- NOTE: there must be a better way to handle this, probably by
            -- plugin into the C implementation of the terminal buffer
          end, 100)

          local lines =
            api.nvim_buf_get_lines(args2.buf, cmd_start[1] - 1, -1, true)
          local new_lines = {} ---@type string[]
          for i, line in ipairs(lines) do
            table.insert(new_lines, line)
            local is_last_new_line = lines[i + 1] == "" and lines[i + 2] == ""
            if is_last_new_line then break end
          end

          update_lines(args2.buf, new_lines, term_keys)
        end,
      })

      api.nvim_create_autocmd("TermRequest", {
        group = editgroup,
        buffer = args.buf,
        callback = function(args2)
          local sequence = args2.data and args2.data.sequence or ""
          local marker = sequence:match("^\027%]133;([ABCD])")
          if not marker then return end

          local bufinfo = M.buffers[args2.buf]
          if marker == "B" then
            bufinfo.cmd_cursor = args2.data.cursor
          else
            bufinfo.cmd_cursor = nil
          end
        end,
      })

      api.nvim_create_autocmd("CursorMoved", {
        group = editgroup,
        buffer = args.buf,
        callback = function(args2)
          local cursor = api.nvim_win_get_cursor(0)
          local bufinfo = M.buffers[args2.buf]
          vim.bo.modifiable = bufinfo.cmd_cursor
            and (
              (
                cursor[1] == bufinfo.cmd_cursor[1]
                and cursor[2] > bufinfo.cmd_cursor[2]
              ) or cursor[1] > bufinfo.cmd_cursor[1]
            )
        end,
      })
    end,
  })
end

return M
