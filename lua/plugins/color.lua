return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000, -- Ensure it loads first
    config = function()
      vim.cmd.colorscheme("onedark")

      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalVertical", { bg = "none" })
      vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
      vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
      vim.api.nvim_set_hl(0, "Terminal", { bg = "none" })
      vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
      vim.api.nvim_set_hl(0, "FoldColumn", { bg = "none" })
      vim.api.nvim_set_hl(0, "Folded", { bg = "none" })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
      vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
      vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "WhichKeyFloat", { bg = "none" })
      vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = "none" })
      vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
      vim.api.nvim_set_hl(0, "TelescopePromptBorder", { bg = "none" })
      vim.api.nvim_set_hl(0, "TelescopePromptTitle", { bg = "none" })

      vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "NeoTreeVertSplit", { bg = "none" })
      vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { bg = "none" })
      vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "none" })

      vim.api.nvim_set_hl(0, "NotifyINFOBody", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyERRORBody", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyWARNBody", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyTRACEBody", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyDEBUGBody", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyINFOTitle", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyERRORTitle", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyWARNTitle", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyTRACETitle", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyDEBUGTitle", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyINFOBorder", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyERRORBorder", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyWARNBorder", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyTRACEBorder", { bg = "none" })
      vim.api.nvim_set_hl(0, "NotifyDEBUGBorder", { bg = "none" })

      vim.api.nvim_set_hl(0, "ToggleTerm", { bg = "none" })
      vim.api.nvim_set_hl(0, "ToggleTermNormal", { bg = "none" })
      vim.api.nvim_set_hl(0, "ToggleTermBorder", { bg = "none" })

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*",
        callback = function()
          vim.wo.winhighlight = ""
          vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
          vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
        end,
      })
    end,
  },
}
