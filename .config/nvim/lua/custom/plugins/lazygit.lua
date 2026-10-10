-- nvr is not used: lazygit talks to this Neovim through `nvim --server $NVIM`
-- (see ~/.config/lazygit/nvim-open.sh)
vim.g.lazygit_use_neovim_remote = 0
vim.g.lazygit_floating_window_scaling_factor = 0.9
vim.g.lazygit_floating_window_use_plenary = 0

vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/kdheepak/lazygit.nvim',
})

vim.keymap.set('n', '<leader>gg', '<cmd>LazyGit<cr>', { desc = 'LazyGit' })

-- File waiting to be opened once the lazygit float has closed
local pending

local function open_pending()
  if not pending then return end
  local file, line = pending.file, pending.line
  pending = nil
  -- never open the file inside a floating/terminal window
  local cur = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(cur).relative ~= '' or vim.bo.buftype == 'terminal' then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(w).relative == '' and vim.bo[vim.api.nvim_win_get_buf(w)].buftype ~= 'terminal' then
        vim.api.nvim_set_current_win(w)
        break
      end
    end
  end
  vim.cmd.edit(vim.fn.fnameescape(file))
  if line > 0 then
    pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    vim.cmd 'normal! zz'
  end
end

vim.g.lazygit_on_exit_callback = function() vim.schedule(open_pending) end

--- Called by lazygit (nvim-open.sh) via `nvim --server $NVIM --remote-expr`.
--- Quits the lazygit float, then opens `file` in the window lazygit was launched from.
function _G.LazygitOpen(file, line)
  pending = { file = file, line = tonumber(line) or 0 }
  vim.schedule(function()
    local lg_buf = LAZYGIT_BUFFER
    local job = lg_buf and vim.api.nvim_buf_is_valid(lg_buf) and vim.b[lg_buf].terminal_job_id
    if job then
      -- quit lazygit; lazygit.nvim's on_exit closes the float and calls open_pending
      vim.fn.chansend(job, 'q')
    else
      -- lazygit running in some other terminal (e.g. toggleterm): just open it
      open_pending()
    end
  end)
  return ''
end
