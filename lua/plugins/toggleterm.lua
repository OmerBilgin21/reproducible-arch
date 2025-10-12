return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      local tt = require("toggleterm")
      local term = require("toggleterm.terminal")
      local Terminal = require("toggleterm.terminal").Terminal

      local base_setup = {
        size = function(term_opts)
          if term_opts.direction == "horizontal" then
            return 15
          elseif term_opts.direction == "vertical" then
            return vim.o.columns * 0.3
          else
            return 20
          end
        end,
        direction = "float",
        float_opts = {
          border = "single",
        },
        title_pos = "center",
        scroll_on_output = false,
      }

      local claude_setup = {
        id = 999,
        direction = "vertical",
        cmd = "claude",
        hidden = true,
        title = "Claude Code",
        scroll_on_output = false,
      }

      local lazygit_setup = vim.tbl_deep_extend("force", {
        id = 998,
        cmd = "lazygit",
        hidden = true,
        title = "LazyGit",
      }, base_setup)

      local default_setup = vim.tbl_deep_extend("force", {
        id = 997,
        hidden = true,
        title = "Terminal",
      }, base_setup)

      -- these are in a function because I need it to be executed
      -- on the runtime not at the startup to get the correct current filename
      local function get_test_setup()
        local current_file = vim.fn.expand("%:t")
        local test_command = "npx jest -- " .. current_file
        local test_setup = vim.tbl_deep_extend("force", {
          cmd = test_command,
          close_on_exit = false,
          title = "Test",
        }, base_setup)

        return test_setup
      end

      local lazygit = Terminal:new(lazygit_setup)
      local claude = Terminal:new(claude_setup)
      local default = Terminal:new(default_setup)
      tt.setup(base_setup)

      vim.keymap.set("n", "<leader>tt", function()
        local test_terminal = Terminal:new(get_test_setup())
        test_terminal:toggle()
      end)

      vim.keymap.set("v", "<C-p>", function()
        require("toggleterm").send_lines_to_terminal("visual_lines", true, { args = claude_setup.id })
      end)

      vim.keymap.set({ "t" }, "<C-p>", function()
        local current_win = vim.api.nvim_get_current_win()
        vim.cmd("wincmd p")
        local filename = vim.fn.expand("%:t")
        vim.api.nvim_set_current_win(current_win)
        if filename ~= "" then
          vim.api.nvim_paste(filename, true, -1)
        end
      end, { noremap = true, silent = true })

      vim.keymap.set("t", "<C-n>", [[<C-\><C-n>]])
      vim.keymap.set({ "i", "n", "t" }, "<S-tab>", function()
        if term.get_focused_id() == 999 then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-tab>", true, false, true), "n", false)
          return
        end
        default:toggle()
      end, { desc = "Close all terminals or open a new one" })

      vim.keymap.set("n", "<leader>gg", function()
        lazygit:toggle()
      end)

      vim.keymap.set({ "n", "t" }, "<C-Space>", function()
        claude:toggle()
      end)

      vim.keymap.set("t", "<C-x>", function()
        if term.get_focused_id() ~= 997 then
          return
        end

        vim.cmd("stopinsert")

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
        vim.api.nvim_buf_set_option(buf, "filetype", "sh")
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })

        local width = math.min(80, vim.o.columns - 4)
        local height = 1
        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          col = math.floor((vim.o.columns - width) / 2),
          row = math.floor((vim.o.lines - height) / 2),
          style = "minimal",
          border = "rounded",
          title = " Command ",
          title_pos = "center",
        })

        vim.keymap.set({ "i", "n" }, "<CR>", function()
          local command = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] or ""
          vim.api.nvim_win_close(win, true)
          default:send(command, false)
          vim.schedule(function()
            default:open()
            vim.cmd("startinsert")
          end)
        end, { buffer = buf })

        local close = function()
          vim.api.nvim_win_close(win, true)
          vim.schedule(function()
            default:open()
            vim.cmd("startinsert")
          end)
        end

        vim.keymap.set("i", "<C-n>", "<Esc>", { buffer = buf })
        vim.keymap.set("n", "<Esc>", close, { buffer = buf })
        vim.keymap.set("n", "q", close, { buffer = buf })

        vim.cmd("startinsert")
      end, { noremap = true })
    end,
  },
}
