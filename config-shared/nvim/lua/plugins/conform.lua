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
      javascript = { "eslint_d", "prettier" },
      javascriptreact = { "eslint_d", "prettier" },
      sql = { "sqlfmt" },
      typescript = { "eslint_d", "prettier" },
      typescriptreact = { "eslint_d", "prettier" },
      go = { "gofmt" },
      json = { "jq" },
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    notify_on_error = true,
    notify_no_formatters = true,
    log_level = vim.log.levels.ERROR,
    format_on_save = {
      timeout_ms = 2000,
      lsp_format = "fallback",
    },
  },
  keys = {
    {
      "<leader>,",
      function()
        require("conform").format()
      end,
      desc = "Format buffer",
    },
  },
}
