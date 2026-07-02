-- Nvim-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-tree/nvim-tree.lua

local plugins = {
  { src = 'https://github.com/nvim-tree/nvim-tree.lua', version = vim.version.range '*' },
}

if vim.g.have_nerd_font then table.insert(plugins, 'https://github.com/nvim-tree/nvim-web-devicons') end

vim.pack.add(plugins)

-- CHANGED: Changed from NvimTreeToggle to NvimTreeFindFileToggle
vim.keymap.set('n', '\\', '<Cmd>NvimTreeFindFileToggle<CR>', { desc = 'NvimTree toggle and find file', silent = true })

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- CHANGED: Added update_focused_file block to automatically focus active files
require("nvim-tree").setup({
  update_focused_file = {
    enable = true,       -- Focuses the file when tree opens or when switching buffers
  },
})
