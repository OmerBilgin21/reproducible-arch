return {
  {
    "willothy/flatten.nvim",
    opts = {
      window = { open = "alternate" },
      hooks = {
        should_block = function(argv)
          if not argv or type(argv) ~= "table" then
            return false
          end
          return vim.tbl_contains(argv, "-b")
            or vim.tbl_contains(argv, "--remote-wait")
            or vim.tbl_contains(argv, "--remote-wait-sleep")
        end,
      },
    },
  },
  {
    "tpope/vim-fugitive",
    config = function()
      vim.keymap.set("n", "<leader>gm", "<cmd>:Gvdiffsplit!<cr>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>gb", "<cmd>:G blame<cr>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>gr", function()
        local back = vim.fn.input("Enter how many times to take back:")
        local cmd = string.format("G reset --soft HEAD~%s", back)
        vim.cmd(cmd)
      end, { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>go", "<cmd>:diffget //2<cr>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>gt", "<cmd>:diffget //3<cr>", { noremap = true, silent = true })

      vim.keymap.set("n", "<leader>gs", "<cmd>G<cr>", { desc = "Git status" })

      vim.keymap.set("n", "<leader>gc", "<cmd>G checkout<cr>", { desc = "Git checkout branch" })
      vim.keymap.set("n", "<leader>gC", function()
        local branch = vim.fn.input("Create and checkout branch: ")
        if branch ~= "" then
          vim.cmd("G checkout -b " .. branch)
        end
      end, { desc = "Create and checkout new branch" })
      vim.keymap.set("n", "<leader>gB", "<cmd>G branch<cr>", { desc = "List branches" })

      -- Commit operations
      vim.keymap.set("n", "<leader>gci", "<cmd>G commit<cr>", { desc = "Git commit" })
      vim.keymap.set("n", "<leader>gca", "<cmd>G commit --amend<cr>", { desc = "Git commit amend" })
      vim.keymap.set("n", "<leader>gcm", function()
        local msg = vim.fn.input("Commit message: ")
        if msg ~= "" then
          vim.cmd("G commit -m '" .. msg .. "'")
        end
      end, { desc = "Quick commit with message" })

      -- Push/Pull operations
      vim.keymap.set("n", "<leader>gp", "<cmd>G push<cr>", { desc = "Git push" })
      vim.keymap.set("n", "<leader>gP", "<cmd>G pull<cr>", { desc = "Git pull" })
      vim.keymap.set("n", "<leader>gf", "<cmd>G fetch<cr>", { desc = "Git fetch" })

      -- Stash operations
      vim.keymap.set("n", "<leader>gst", "<cmd>G stash<cr>", { desc = "Git stash" })
      vim.keymap.set("n", "<leader>gsp", "<cmd>G stash pop<cr>", { desc = "Git stash pop" })
      vim.keymap.set("n", "<leader>gsl", "<cmd>G stash list<cr>", { desc = "Git stash list" })

      -- Log and history
      vim.keymap.set("n", "<leader>gl", "<cmd>G log<cr>", { desc = "Git log detailed" })
      vim.keymap.set(
        "n",
        "<leader>gL",
        "<cmd>G log --oneline --graph --all<cr>",
        { desc = "Git log graph all branches" }
      )

      vim.keymap.set("n", "<leader>glc", "<cmd>G log --oneline<cr>", { desc = "Git log compact" })

      -- Branch operations (enhanced)
      vim.keymap.set("n", "<leader>gbs", function()
        vim.cmd("G branch -a")
      end, { desc = "Show all branches (local and remote)" })

      -- View unpushed/pushed commits
      vim.keymap.set("n", "<leader>gpu", function()
        local branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
        vim.cmd("G log origin/" .. branch .. "..HEAD --oneline")
      end, { desc = "Show unpushed commits" })

      vim.keymap.set("n", "<leader>gpd", function()
        local branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
        vim.cmd("G log HEAD..origin/" .. branch .. " --oneline")
      end, { desc = "Show commits to pull" })

      -- Show commits in current branch (not in main/master)
      vim.keymap.set("n", "<leader>glb", function()
        local main_branches = { "main", "master", "develop" }
        local branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
        local main_branch = nil

        -- Find which main branch exists
        for _, mb in ipairs(main_branches) do
          local result = vim.fn.system("git show-ref --verify --quiet refs/heads/" .. mb)
          if vim.v.shell_error == 0 then
            main_branch = mb
            break
          end
        end

        if main_branch and branch ~= main_branch then
          vim.cmd("G log " .. main_branch .. ".." .. branch .. " --oneline")
        else
          vim.cmd("G log --oneline -10")
        end
      end, { desc = "Show commits in current branch" })

      -- Diff operations (enhanced)
      vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit<cr>", { desc = "Git diff split" })

      -- Git status buffer specific mappings (these work when you're in the :G buffer)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fugitive",
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local opts = { buffer = bufnr, silent = true }

          -- Enhanced staging shortcuts in fugitive buffer
          vim.keymap.set("n", "cc", "<cmd>G commit<cr>", opts)
          vim.keymap.set("n", "P", "<cmd>G push<cr>", opts)
          vim.keymap.set("n", "p", "<cmd>G pull<cr>", opts)

          vim.keymap.set("n", "X", "X", opts)
          vim.keymap.set("n", "<leader>gX", "<cmd>G reset --hard HEAD<cr>", opts) -- Discard all changes
        end,
      })

      -- Quickfix shortcuts for better navigation
      vim.keymap.set("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
      vim.keymap.set("n", "[q", "<cmd>cprev<cr>", { desc = "Previous quickfix" })
      vim.keymap.set("n", "<leader>qc", "<cmd>cclose<cr>", { desc = "Close quickfix" })
    end,
  },
}
