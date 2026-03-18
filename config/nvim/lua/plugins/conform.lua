return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      sh = { "shfmt" },
      zsh = { "shfmt" },
      bash = { "shfmt" },
      python = { "isort", "black" },
      javascript = {
        "prettier",
        stop_after_first = true,
      },
      javascriptreact = {
        "prettier",
        stop_after_first = true,
      },
      sql = { "sqlfmt" },
      typescript = {
        "prettier",
        stop_after_first = true,
      },
      typescriptreact = {
        "prettier",
        stop_after_first = true,
      },
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
