return {
  "kristijanhusak/vim-dadbod-ui",
  lazy = true,
  dependencies = {
    {
      "tpope/vim-dadbod",
      lazy = true,
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "plsql" }, lazy = true },
    },
  },
  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },
  init = function()
    vim.g.db_ui_execute_on_save = 0
    vim.g.db_ui_save_location = vim.fn.expand("~/queries")
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.vim_dadbod_completion_omnifunc = 0
  end,
}
