return {
  { "mfussenegger/nvim-dap" },
  {
    "leoluz/nvim-dap-go",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      require("dap-go").setup({
        dap_configurations = {
          {
            type = "go",
            name = "Attach remote",
            mode = "remote",
            request = "attach",
          },
        },
        delve = {
          path = vim.fn.stdpath("data") .. "/mason/bin/dlv",
        },
      })
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
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
    -- name = "print-debugger",
    -- dir = "/home/oemer/projects/print-debugger",
    version = false,
    config = function()
      require("print-debugger").setup({
        typescript = {
          prefix = "logger.info",
        },
        go = {
          -- prefix = "util.Log",
          -- spread_mode = true,
        },
        keymaps = {
          "<C-g>",
        },
      })
    end,
  },
}
