return {
  { "mfussenegger/nvim-dap" },
  {
    "leoluz/nvim-dap-go",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      require("dap-go").setup({
        delve = {
          path = vim.fn.stdpath("data") .. "/mason/bin/dlv",
        },
      })
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    keys = {
      -- debug the test function your cursor is inside
      {
        "<leader>dt",
        function()
          require("dap-go").debug_test()
        end,
        desc = "Debug test",
      },
      -- breakpoints
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      -- execution control
      {
        "<F5>",
        function()
          require("dap").continue()
        end,
        desc = "Continue",
      },
      {
        "<F10>",
        function()
          require("dap").step_over()
        end,
        desc = "Step over",
      },
      {
        "<F11>",
        function()
          require("dap").step_into()
        end,
        desc = "Step into",
      },
      {
        "<F12>",
        function()
          require("dap").step_out()
        end,
        desc = "Step out",
      },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      -- open/close the UI automatically when a debug session starts/ends
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end,
  },
  {
    "OmerBilgin21/print-debugger.nvim",
    -- dir = "/home/oemer/projects/print-debugger",
    version = false,
    config = function()
      require("print-debugger").setup({
        -- typescript = { prefix = "logger.info" },
        -- go = { prefix = "internal.Logger", spread_mode = true },
        keymaps = { "<C-g>" },
      })
    end,
  },
}
