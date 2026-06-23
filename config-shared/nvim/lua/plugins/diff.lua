return {
  {
    "sindrets/diffview.nvim",
    keys = {
      {
        "<leader>do",
        "<CMD>DiffviewOpen<CR>",
        desc = "Open Diffview",
      },
      {
        "<leader>dc",
        "<CMD>DiffviewClose<CR>",
        desc = "Close Diffview",
      },
    },
  },
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Octo",
    opts = {
      picker = "telescope",
      enable_builtin = true,
    },
    keys = {
      {
        "<leader>op",
        "<CMD>Octo pr list<CR>",
        desc = "List GitHub PullRequests",
      },
      {
        "<leader>or",
        "<CMD>Octo review<CR>",
        desc = "Review GitHub PullRequests",
      },
      {
        "<leader>os",
        "<CMD>Octo review submit<CR>",
        desc = "Submit PullRequests review",
      },
    },
  },
}
