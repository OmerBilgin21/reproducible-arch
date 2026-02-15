return {
  "OmerBilgin21/print-debugger.nvim",
  -- name = "print-debugger",
  -- dir = "/home/oemer/projects/print-debugger",
  version = false,
  config = function()
    require("print-debugger").setup({
      typescript = {
        prefix = "logger.info",
      },
      go = {
        prefix = "util.Log",
        spread_mode = true,
      },
      keymaps = {
        "<C-g>",
      },
    })
  end,
}
