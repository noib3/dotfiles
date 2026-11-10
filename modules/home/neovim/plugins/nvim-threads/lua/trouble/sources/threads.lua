local Item = require("trouble.item")
local render = require("nvim_threads.render")
local threads = require("nvim_threads")

local M = {}

---@class nvim_threads.trouble.Entry
---@field thread nvim_threads.Thread
---@field status "waiting on agent"|"waiting on me"
---@field title string

M.config = {
  formatters = {
    threads_status = function(ctx)
      ---@type nvim_threads.trouble.Entry
      local entry = ctx.item.item
      if entry.status == "waiting on agent" then
        return { text = "…", hl = "ThreadsWaitingOnAgent" }
      end
      return { text = render.waiting_on_me_icon, hl = "ThreadsWaitingOnMe" }
    end,
  },
  modes = {
    threads = {
      desc = "Threads of the working-copy change",
      source = "threads",
      events = { { event = "User", pattern = "NvimThreadsChanged" } },
      groups = { { "filename", format = "{file_icon} {filename} {count}" } },
      sort = { "filename", "pos" },
      format = "{threads_status} {text} {pos}",
    },
    threads_waiting_on_me = {
      desc = "Threads of the working-copy change waiting on me",
      mode = "threads",
      filter = { status = "waiting on me" },
    },
  },
}

--- Lists the threads of the working-copy commit of the workspace around the
--- list's `cwd` option, or else the current working directory.
---@param cb fun(items: trouble.Item[])
---@param ctx { opts: { cwd?: string } }
M.get = function(cb, ctx)
  local dir = ctx.opts.cwd or vim.fn.getcwd()
  threads.list(dir, function(listed)
    local items = {}
    for _, entry in ipairs(listed) do
      local anchor = entry.thread.anchor
      local filename = vim.fs.joinpath(entry.root, entry.path)
      items[#items + 1] = Item.new({
        id = entry.thread.id,
        filename = filename,
        pos = { anchor.start_row + 1, anchor.start_col },
        end_pos = { anchor.end_row + 1, anchor.end_col },
        text = threads.title(entry.thread),
        item = {
          thread = entry.thread,
          status = entry.status,
          title = threads.title(entry.thread),
        },
        source = "threads",
      })
    end
    cb(items)
  end)
end

return M
