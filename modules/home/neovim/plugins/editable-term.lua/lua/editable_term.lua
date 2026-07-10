-- TODO: create a PR to add to Neovim

local api = vim.api

local M = {}

local cell_to_byte

---@param position any
---@return boolean
local function is_position(position)
  return type(position) == "table"
    and type(position[1]) == "number"
    and type(position[2]) == "number"
end

---@param a {[1]: integer, [2]: integer}
---@param b {[1]: integer, [2]: integer}
---@return boolean
local function position_lt(a, b)
  return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
end

---@param buf integer
---@param cmd_start any
---@param cursor any
---@return boolean
local function cursor_in_cmd_region(buf, cmd_start, cursor)
  if not is_position(cmd_start) or not is_position(cursor) then return false end
  if not api.nvim_buf_is_valid(buf) then return false end
  if cursor[1] < 1 or cursor[1] > api.nvim_buf_line_count(buf) then
    return false
  end
  if cursor[1] ~= cmd_start[1] then
    return not position_lt(cursor, cmd_start)
  end

  local line = api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], true)[1]
  return cursor[2] >= cell_to_byte(line, cmd_start[2])
end

---@param line string
---@param byteidx integer
---@return integer
local function byte_to_utf32_index(line, byteidx)
  byteidx = math.max(0, math.min(byteidx, #line))
  local ok, index = pcall(vim.str_utfindex, line, "utf-32", byteidx, true)
  if ok and index then return index end

  -- Be conservative around stale terminal cursor positions or byte offsets
  -- that have drifted into the middle of a multibyte character.
  return vim.str_utfindex(line, "utf-32", byteidx, false)
end

---@param line string
---@param cell integer
---@return integer byteidx
---@return integer utf32idx
cell_to_byte = function(line, cell)
  cell = math.max(0, cell)
  local cells = 0
  local n_chars = vim.str_utfindex(line, "utf-32")

  for charidx = 0, n_chars - 1 do
    local byteidx = vim.str_byteindex(line, "utf-32", charidx)
    local next_byteidx = vim.str_byteindex(line, "utf-32", charidx + 1)
    local char = line:sub(byteidx + 1, next_byteidx)
    local width = math.max(0, vim.fn.strdisplaywidth(char))

    if cells + width > cell then return byteidx, charidx end
    cells = cells + width
  end

  return #line, n_chars
end

---@param line string
---@param cell integer
---@return integer
local function cell_to_utf32_index(line, cell)
  local _, charidx = cell_to_byte(line, cell)
  return charidx
end

---@param buf integer
---@param cmd_start {[1]: integer, [2]: integer}
---@param cursor {[1]: integer, [2]: integer}
---@return integer?
local function n_forward_chars_to_cursor(buf, cmd_start, cursor)
  if not cursor_in_cmd_region(buf, cmd_start, cursor) then return nil end

  local lines = api.nvim_buf_get_lines(buf, cmd_start[1] - 1, cursor[1], true)
  if #lines == 0 then return nil end

  if cursor[1] == cmd_start[1] then
    local line = lines[1]
    return math.max(
      0,
      byte_to_utf32_index(line, cursor[2])
        - cell_to_utf32_index(line, cmd_start[2])
    )
  end

  local n_forward_chars = 0
  for i, line in ipairs(lines) do
    if i == 1 then
      n_forward_chars = n_forward_chars
        + byte_to_utf32_index(line, #line)
        - cell_to_utf32_index(line, cmd_start[2])
    elseif i == #lines then
      n_forward_chars = n_forward_chars + byte_to_utf32_index(line, cursor[2])
    else
      n_forward_chars = n_forward_chars + byte_to_utf32_index(line, #line)
    end
  end

  return math.max(0, n_forward_chars)
end

---@param buf integer
---@param cursor {[1]: integer, [2]: integer}
---@param term_keys editable_term.TermKeys
---@return boolean
local function set_term_cursor(buf, cursor, term_keys)
  local bufinfo = M.buffers[buf]
  if not bufinfo then return false end
  local cmd_start = bufinfo.cmd_cursor
  local n_forward_chars = cmd_start
    and n_forward_chars_to_cursor(buf, cmd_start, cursor)
  if not n_forward_chars then return false end

  local movement_chars = vim.keycode(term_keys.goto_line_start)
    .. vim.keycode(term_keys.forward_char):rep(n_forward_chars)
  vim.fn.chansend(vim.bo[buf].channel, movement_chars)
  return true
end

---@param buf integer
---@param new_lines string[]
---@param term_keys editable_term.TermKeys
local function update_lines(buf, new_lines, term_keys)
  local bufinfo = M.buffers[buf]
  if not bufinfo then return end
  local cmd_start = bufinfo.cmd_cursor
  if not cmd_start then return end

  local new_term_line_segments = {} ---@type string[]
  for i, line in ipairs(new_lines) do
    if line ~= "" then
      if i == 1 then
        local cmd_start_byte_index = cell_to_byte(line, cmd_start[2])
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
        vim.fn.chansend(
          vim.bo[args.buf].channel,
          vim.keycode(term_keys.goto_line_end)
        )
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set("n", "I", function()
        vim.fn.chansend(
          vim.bo[args.buf].channel,
          vim.keycode(term_keys.goto_line_start)
        )
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set("n", "i", function()
        local bufinfo = M.buffers[args.buf]
        local cursor = api.nvim_win_get_cursor(0)
        if
          bufinfo
          and bufinfo.cmd_cursor
          and cursor_in_cmd_region(args.buf, bufinfo.cmd_cursor, cursor)
        then
          if not set_term_cursor(args.buf, cursor, term_keys) then
            vim.fn.chansend(
              vim.bo[args.buf].channel,
              vim.keycode(term_keys.goto_line_end)
            )
          end
        else
          vim.fn.chansend(
            vim.bo[args.buf].channel,
            vim.keycode(term_keys.goto_line_end)
          )
        end
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set("n", "a", function()
        local bufinfo = M.buffers[args.buf]
        local cursor = api.nvim_win_get_cursor(0)
        if
          bufinfo
          and bufinfo.cmd_cursor
          and cursor_in_cmd_region(args.buf, bufinfo.cmd_cursor, cursor)
        then
          cursor[2] = cursor[2] + 1
          if not set_term_cursor(args.buf, cursor, term_keys) then
            vim.fn.chansend(
              vim.bo[args.buf].channel,
              vim.keycode(term_keys.goto_line_end)
            )
          end
        else
          vim.fn.chansend(
            vim.bo[args.buf].channel,
            vim.keycode(term_keys.goto_line_end)
          )
        end
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set(
        "n",
        "dd",
        function()
          vim.fn.chansend(
            vim.bo[args.buf].channel,
            vim.keycode(
              term_keys.clear_current_line .. term_keys.goto_line_start
            )
          )
        end,
        { buffer = args.buf }
      )

      vim.keymap.set("n", "cc", function()
        vim.fn.chansend(
          vim.bo[args.buf].channel,
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
          if not bufinfo then return end
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
            vim.fn.chansend(vim.bo[args2.buf].channel, vim.keycode("<c-c>"))
            return
          end

          -- TODO: use vim.range here and everywhere when creating a PR to Neovim
          if
            not cursor_in_cmd_region(args2.buf, cmd_start, start_point)
            or not cursor_in_cmd_region(args2.buf, cmd_start, end_point)
          then
            vim.fn.chansend(vim.bo[args2.buf].channel, vim.keycode("<c-c>"))
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
          if not bufinfo then return end
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
          if not bufinfo then return end
          if marker == "B" and is_position(args2.data.cursor) then
            bufinfo.cmd_cursor = args2.data.cursor
          else
            bufinfo.cmd_cursor = nil
          end
        end,
      })

      -- Terminal reflow can move prompt lines without preserving the OSC 133
      -- cursor snapshot we stored, so invalidate it and wait for the shell's
      -- next prompt marker to set it.
      api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
        group = editgroup,
        callback = function()
          local bufinfo = M.buffers[args.buf]
          if bufinfo then bufinfo.cmd_cursor = nil end
        end,
      })

      api.nvim_create_autocmd("CursorMoved", {
        group = editgroup,
        buffer = args.buf,
        callback = function(args2)
          local cursor = api.nvim_win_get_cursor(0)
          local bufinfo = M.buffers[args2.buf]
          vim.bo[args2.buf].modifiable = (
            bufinfo
            and cursor_in_cmd_region(args2.buf, bufinfo.cmd_cursor, cursor)
          ) or false
        end,
      })
    end,
  })
end

return M
