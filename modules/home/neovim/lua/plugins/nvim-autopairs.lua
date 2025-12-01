return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
    config = function(opts)
      local npairs = require("nvim-autopairs")
      local Rule = require("nvim-autopairs.rule")
      local ts_conds = require("nvim-autopairs.ts-conds")

      npairs.setup(opts)

      -- In Rust, only pair single quotes when inside strings or comments.
      npairs.add_rules({
        Rule("'", "'", "rust")
            :with_pair(ts_conds.is_ts_node({
              "string_literal",
              "string_content",
              "raw_string_literal",
              "line_comment",
              "block_comment",
            }))
      })
    end
  }
}
