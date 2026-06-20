local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("config")
require("lazy").setup("plugins", { root = "~/reproducible-arch/config-shared/nvim/plugin-code/" })

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyUpdate",
  callback = function()
    vim.fn.system("find ~/reproducible-arch/config-shared/nvim/plugin-code -name '.git' -type d -exec rm -rf {} +")
    vim.fn.system("rm -f ~/reproducible-arch/config-shared/nvim/plugin-code/blink.cmp/target/release/version")
  end,
})

require("config.landing").setup()
