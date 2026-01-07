-- Customize none-ls sources

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    -- Prefer none-ls module name, but keep backward-compatible fallback.
    local ok, null_ls = pcall(require, "none-ls")
    if not ok then null_ls = require "null-ls" end

    opts.sources = require("astrocore").list_insert_unique(opts.sources or {}, {
      null_ls.builtins.formatting.black,
      -- null_ls.builtins.formatting.stylua,
      -- null_ls.builtins.formatting.prettier,
    })

    return opts
  end,
}
