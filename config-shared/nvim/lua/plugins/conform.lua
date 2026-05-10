return {
  "stevearc/conform.nvim",
  lazy = false,
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      sh = { "shfmt" },
      zsh = { "shfmt" },
      bash = { "shfmt" },
      python = { "isort", "black" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      sql = { "sqlfmt" },
      go = { "gofmt" },
      json = { "jq" },
    },
    default_format_opts = {
      stop_after_first = true,
      lsp_format = "fallback",
    },
    notify_on_error = true,
    notify_no_formatters = true,
    log_level = vim.log.levels.ERROR,
    format_after_save = {
      lsp_format = "fallback",
    },
  },
  keys = {
    {
      "<leader>,",
      function()
        require("conform").format({ async = true })
      end,
      desc = "Format buffer",
    },
    {
      "<C-s>",
      function()
        require("conform").format({ async = true }, function()
          vim.cmd("write")
        end)
      end,
      desc = "Format and save",
    },
  },
}
