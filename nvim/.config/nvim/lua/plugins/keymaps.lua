return {
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.mappings.n["R"] = {
        function() require("astrocore.buffer").nav(vim.v.count1) end,
        desc = "Next buffer",
      }
      opts.mappings.n["E"] = {
        function() require("astrocore.buffer").nav(-vim.v.count1) end,
        desc = "Previous buffer",
      }
      opts.mappings.n["x"] = {
        "<Nop>",
        desc = "Disable default x",
      }
      opts.mappings.n["x"] = {
        function() require("astrocore.buffer").close() end,
        desc = "Close buffer",
      }
    end,
  },
}
