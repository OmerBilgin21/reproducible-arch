return {
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
    },
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")

      harpoon:setup()

      vim.keymap.set("n", "<leader>H", function()
        harpoon:list():add()
      end)
      vim.keymap.set("n", "<leader>h", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)

      for i = 1, 5 do
        local index = i
        vim.keymap.set("n", "<leader>" .. index, function()
          harpoon:list():select(index)
        end)
      end
    end,
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    init = function()
      vim.g.nvim_surround_no_insert_mappings = true
    end,
    opts = {},
  },
  {
    "echasnovski/mini.pairs",
    config = {
      modes = { insert = true, command = true, terminal = false },
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      skip_ts = { "string" },
      skip_unbalanced = true,
      markdown = true,
    },
  },
  {
    "MagicDuck/grug-far.nvim",
    config = { headerMaxWidth = 80 },
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          local grug = require("grug-far")
          print("grug: ", grug)
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.toggle_instance({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
    },
  },
  {
    url = "https://codeberg.org/andyg/leap.nvim",
    name = "leap.nvim",
    config = function()
      local curr_file = vim.bo.filetype

      if curr_file == "trouble" or curr_file == "lazy" then
        return
      end

      local leap = require("leap")
      leap.setup({
        equivalence_classes = { " \t\r\n", "([{", ")]}", "'\"`" },
        preview_filter = function(c0, c1, c2)
          return not (c1:match("%s") or c0:match("%w") and c1:match("%w") and c2:match("%w"))
        end,
      })
      vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)")
      vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)")

      local user = require("leap.user")
      user.set_repeat_keys("<enter>", "<backspace>")
    end,
  },
}
