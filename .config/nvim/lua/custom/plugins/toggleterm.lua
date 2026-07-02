vim.pack.add({
  "https://github.com/akinsho/toggleterm.nvim",
})

-- 2. Execute ToggleTerm setup with floating terminal presets
require("toggleterm").setup({
  size = 20,
  open_mapping = [[<c-\>]], -- Press Ctrl + \ to toggle universally
  hide_numbers = false,
  shade_terminals = false,
  start_in_insert = true,
  insert_mappings = true,
  terminal_mappings = true,
  persist_size = true,
  direction = "float",      -- Enforce default floating layouts
  close_on_exit = true,
  shell = vim.o.shell,
  float_opts = {
    border = "curved",     -- Elegant rounded borders
    winblend = 0,
  },
    -- CRITICAL: Force solid background groups inside the float
  highlights = {
    NormalFloat = {
      link = "NormalSB" -- Links the terminal float to TokyoNight's solid sidebar color
    },
    FloatBorder = {
      -- Keeps the hover window border solid as well
      bg = "#1a1b26",  -- Replace with your preferred dark solid background hex color
      fg = "#3b4261",  -- Border line color
    },
  },
})

-- 3. Setup Two Persistent Float Window Mappings (Ctrl + t and Ctrl + a)
local Terminal = require('toggleterm.terminal').Terminal

-- Create Terminal 1 with ID 1
local float_term_1 = Terminal:new({ id = 1, direction = "float", hidden = true })
function _G._float_term_1_toggle()
  float_term_1:toggle()
end

-- Create Terminal 2 with ID 2
local float_term_2 = Terminal:new({ id = 2, direction = "float", hidden = true })
function _G._float_term_2_toggle()
  float_term_2:toggle()
end

vim.keymap.set({'n', 't'}, '<C-t>', '<cmd>lua _float_term_1_toggle()<CR>', { silent = true, desc = "Toggle Float Term 1" })
vim.keymap.set({'n', 't'}, '<M-t>', '<cmd>lua _float_term_2_toggle()<CR>', { silent = true, desc = "Toggle Float Term 2" })
