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
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "DAP continue / pick config",
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
    "mxsdev/nvim-dap-vscode-js",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      require("dap-vscode-js").setup({
        debugger_cmd = { "js-debug-adapter" },
        adapters = { "pwa-node" },
      })

      local dap = require("dap")
      for _, lang in ipairs({ "typescript", "javascript" }) do
        dap.configurations[lang] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Jest: current file",
            runtimeExecutable = "node",
            runtimeArgs = {
              "./node_modules/jest/bin/jest.js",
              "--runInBand",
              "--forceExit",
              "--no-coverage",
              "${file}",
            },
            rootPath = "${workspaceFolder}",
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
            sourceMaps = true,
            skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach: local-staging (SAM, port 9229)",
            address = "localhost",
            port = 9229,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            resolveSourceMapLocations = {
              "${workspaceFolder}/**",
              "!**/node_modules/**",
            },
            skipFiles = { "<node_internals>/**", "**/node_modules/**" },
            restart = true,
          },
        }
      end
    end,
  },
  {
    "OmerBilgin21/print-debugger.nvim",
    -- dir = "/home/oemer/projects/print-debugger",
    version = false,
    config = function()
      require("print-debugger").setup({
        typescript = { prefix = "logger.info" },
        -- go = { prefix = "internal.Logger", spread_mode = true },
        keymaps = { "<C-g>" },
      })
    end,
  },
}
