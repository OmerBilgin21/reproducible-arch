return {
  {
    "sindrets/diffview.nvim",
    config = function()
      require("custom.pr-review").setup()
    end,
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
      {
        "<leader>dr",
        function()
          require("custom.pr-review").start()
        end,
        desc = "Review branch with claude-code",
      },
      {
        "<leader>dn",
        function()
          require("custom.pr-review").add_comment()
        end,
        mode = { "n", "x" },
        desc = "PR review: add comment",
      },
      {
        "<leader>dv",
        function()
          require("custom.pr-review").mark_viable()
        end,
        desc = "PR review: mark claude comment viable",
      },
      {
        "<leader>dx",
        function()
          require("custom.pr-review").discard()
        end,
        desc = "PR review: discard comment",
      },
      {
        "<leader>dp",
        function()
          require("custom.pr-review").peek()
        end,
        desc = "PR review: peek comment",
      },
      {
        "<leader>ds",
        function()
          require("custom.pr-review").submit()
        end,
        desc = "PR review: submit review",
      },
    },
  },
  -- {
  --   "pwntester/octo.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-telescope/telescope.nvim",
  --     "nvim-tree/nvim-web-devicons",
  --   },
  --   cmd = "Octo",
  --   opts = {
  --     picker = "telescope",
  --     enable_builtin = true,
  --   },
  --   keys = {
  --     {
  --       "<leader>op",
  --       "<CMD>Octo pr list<CR>",
  --       desc = "List GitHub PullRequests",
  --     },
  --     {
  --       "<leader>or",
  --       "<CMD>Octo review<CR>",
  --       desc = "Review GitHub PullRequests",
  --     },
  --     {
  --       "<leader>os",
  --       "<CMD>Octo review submit<CR>",
  --       desc = "Submit PullRequests review",
  --     },
  --   },
  -- },
}
