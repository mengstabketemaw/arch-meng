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

-- Worktrees: each one runs in its own Neovim in its own kitty tab (see
-- ~/.config/lazygit/worktree-open.sh, also bound to `o` in lazygit's Worktrees panel)
local worktree_open = vim.fn.expand '~/.config/lazygit/worktree-open.sh'

--- Telescope picker over `git worktree list`; <CR> jumps to (or opens) that worktree's tab
local function pick_worktree()
  local out = vim.system({ 'git', 'worktree', 'list', '--porcelain' }, { text = true }):wait()
  if out.code ~= 0 then return vim.notify('Not inside a git repository', vim.log.levels.WARN) end

  local worktrees, wt = {}, nil
  for line in (out.stdout .. '\n'):gmatch '([^\n]*)\n' do
    local key, val = line:match '^(%S+)%s?(.*)$'
    if key == 'worktree' then
      wt = { path = val, branch = 'detached' }
      table.insert(worktrees, wt)
    elseif key == 'branch' and wt then
      wt.branch = val:gsub('^refs/heads/', '')
    end
  end

  local cwd = vim.fn.getcwd()
  local entry_display = require('telescope.pickers.entry_display').create {
    separator = '  ',
    items = { { width = 2 }, { width = 40 }, { remaining = true } },
  }
  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Git Worktrees',
      finder = require('telescope.finders').new_table {
        results = worktrees,
        entry_maker = function(w)
          return {
            value = w,
            ordinal = w.branch .. ' ' .. w.path,
            display = function()
              return entry_display {
                { w.path == cwd and '●' or ' ', 'DiagnosticOk' },
                { w.branch, 'Identifier' },
                { vim.fn.fnamemodify(w.path, ':~'), 'Comment' },
              }
            end,
          }
        end,
      },
      sorter = require('telescope.config').values.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        require('telescope.actions').select_default:replace(function()
          local entry = require('telescope.actions.state').get_selected_entry()
          require('telescope.actions').close(prompt_bufnr)
          if not entry then return end
          vim.system({ worktree_open, entry.value.path }, { text = true }, function(res)
            if res.code ~= 0 then
              vim.schedule(function() vim.notify(vim.trim(res.stderr), vim.log.levels.ERROR) end)
            end
          end)
        end)
        return true
      end,
    })
    :find()
end

vim.keymap.set('n', '<leader>gw', pick_worktree, { desc = '[G]it [W]orktrees (switch tab)' })
