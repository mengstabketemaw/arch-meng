-- debug.lua
--
-- nvim-dap + dap-ui, set up to feel like IntelliJ's debugger:
--   * IntelliJ keys (F7 into, F8 over, Shift+F8 out, F9 resume, Ctrl+F8 breakpoint)
--   * the execution line is highlighted and the code view follows each step
--   * variable values are shown inline next to the code
--   * "Run" sessions (no debugging) only show the console, like IntelliJ's Run tab

vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/theHamsta/nvim-dap-virtual-text',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/jay-babu/mason-nvim-dap.nvim',
  'https://github.com/leoluz/nvim-dap-go',
}

local dap = require 'dap'
local dapui = require 'dapui'

-- [[ Keymaps ]]
-- Terminals send Shift/Ctrl+F-keys either as <S-F8>/<C-F8> or as F20/F32;
-- map both so it works everywhere.
local function map(keys, fn, desc)
  for _, key in ipairs(type(keys) == 'table' and keys or { keys }) do
    vim.keymap.set('n', key, fn, { desc = 'Debug: ' .. desc })
  end
end

map({ '<F9>', '<F5>' }, dap.continue, 'Resume / start')
map('<F8>', dap.step_over, 'Step over')
map('<F7>', dap.step_into, 'Step into')
map({ '<S-F8>', '<F20>' }, dap.step_out, 'Step out')
map({ '<A-F9>', '<F57>' }, dap.run_to_cursor, 'Run to cursor')
map({ '<C-F8>', '<F32>' }, dap.toggle_breakpoint, 'Toggle breakpoint')
map('<leader>b', dap.toggle_breakpoint, 'Toggle breakpoint')
map('<leader>B', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, 'Conditional breakpoint')
map({ '<A-F8>', '<F56>' }, function() dapui.eval(nil, { enter = true }) end, 'Evaluate expression under cursor')
map('<leader>du', function() dapui.toggle { reset = true } end, 'Toggle debug panels')
map('<leader>de', function() dapui.eval(nil, { enter = true }) end, 'Evaluate expression under cursor')
map('<leader>dx', function() dap.clear_breakpoints() end, 'Clear all breakpoints')
map('<leader>dl', function() dap.list_breakpoints(true) end, 'List breakpoints')

require('mason-nvim-dap').setup {
  automatic_installation = true,
  handlers = {},
  ensure_installed = { 'delve', 'javadbg' },
}

-- [[ Look ]]
-- Execution point: full-width highlighted line + arrow (IntelliJ's blue bar)
vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#f7768e' })
vim.api.nvim_set_hl(0, 'DapLogPoint', { fg = '#7aa2f7' })
vim.api.nvim_set_hl(0, 'DapStop', { fg = '#e0af68' })
vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = '#2e3c64' })
vim.api.nvim_set_hl(0, 'DapBreakpointLine', { bg = '#3b2030' })

local nf = vim.g.have_nerd_font
vim.fn.sign_define('DapBreakpoint', { text = nf and '' or '●', texthl = 'DapBreak', linehl = 'DapBreakpointLine' })
vim.fn.sign_define('DapBreakpointCondition', { text = nf and '' or '◆', texthl = 'DapBreak', linehl = 'DapBreakpointLine' })
vim.fn.sign_define('DapBreakpointRejected', { text = nf and '' or '○', texthl = 'DapBreak' })
vim.fn.sign_define('DapLogPoint', { text = nf and '' or '◆', texthl = 'DapLogPoint' })
vim.fn.sign_define('DapStopped', { text = nf and '' or '→', texthl = 'DapStop', linehl = 'DapStoppedLine' })

-- Variable values shown inline at the end of the line, changed ones highlighted
require('nvim-dap-virtual-text').setup {
  virt_text_pos = 'eol',
  highlight_changed_variables = true,
  commented = false,
  all_frames = false,
}
vim.api.nvim_set_hl(0, 'NvimDapVirtualText', { fg = '#7a88cf', italic = true })
vim.api.nvim_set_hl(0, 'NvimDapVirtualTextChanged', { fg = '#ff9e64', italic = true, bold = true })

-- [[ Follow the execution point ]]
-- When stopped, jump into an existing code window (never a dap-ui panel) and
-- open stepped-into files there, then keep the current line comfortably in view.
dap.defaults.fallback.switchbuf = 'usevisible,usetab,uselast'

local function follow_execution(session)
  local frame = session and session.current_frame
  if not frame or not frame.line then return end
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].filetype:match '^dap' then return end
  local top, bottom = vim.fn.line 'w0', vim.fn.line 'w$'
  local margin = math.floor((bottom - top) / 4)
  if frame.line < top + margin or frame.line > bottom - margin then vim.cmd 'normal! zz' end
end

-- nvim-dap requests the scopes right after it jumped to the stopped frame
dap.listeners.after.scopes['follow-execution'] = function(session) vim.schedule(function() follow_execution(session) end) end

-- [[ Panels ]]
-- Debugger panels on the left (IntelliJ "Debugger" tab). Program output lives
-- in its own console split at the bottom (see below), not in dap-ui.
---@diagnostic disable-next-line: missing-fields
dapui.setup {
  icons = { expanded = '▾', collapsed = '▸', current_frame = '→' },
  layouts = {
    {
      position = 'left',
      size = 50,
      elements = {
        { id = 'scopes', size = 0.5 },
        { id = 'stacks', size = 0.2 },
        { id = 'watches', size = 0.1 },
        { id = 'breakpoints', size = 0.1 },
        { id = 'repl', size = 0.1 },
      },
    },
  },
  ---@diagnostic disable-next-line: missing-fields
  controls = { enabled = false },
  floating = { border = 'rounded' },
}

-- [[ Program console ]] (IntelliJ "Run" / "Console" tab)
-- Every run gets a fresh terminal buffer. dap-ui's console reuses one buffer,
-- so starting a run while the previous program was still attached to it
-- failed with "Failed to launch debuggee in terminal ... TimeoutException".
local console = { win = nil, buf = nil }

dap.defaults.fallback.terminal_win_cmd = function() return vim.api.nvim_create_buf(false, true) end

local function console_open() return console.win and vim.api.nvim_win_is_valid(console.win) end

local function show_console(buf)
  buf = buf or console.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return vim.notify('No program output yet — run something first', vim.log.levels.INFO)
  end
  local old = console.buf
  console.buf = buf
  if console_open() then
    vim.api.nvim_win_set_buf(console.win, buf)
  else
    local prev = vim.api.nvim_get_current_win()
    vim.cmd 'botright 12split'
    console.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(console.win, buf)
    vim.wo[console.win].number = false
    vim.wo[console.win].relativenumber = false
    vim.wo[console.win].signcolumn = 'no'
    vim.wo[console.win].winfixheight = true
    vim.api.nvim_set_current_win(prev) -- keep editing; the console just shows output
  end
  -- cursor on the last line = the terminal keeps following new output
  vim.api.nvim_win_call(console.win, function() vim.cmd 'normal! G' end)
  if old and old ~= buf and vim.api.nvim_buf_is_valid(old) then pcall(vim.api.nvim_buf_delete, old, { force = true }) end
end

local function toggle_console()
  if console_open() then
    vim.api.nvim_win_close(console.win, true)
  else
    show_console()
  end
end
map('<leader>dc', toggle_console, 'Toggle program console (output)')
vim.api.nvim_create_user_command('DapConsole', function() show_console() end, { desc = 'Show the program console' })

-- Hooked on the launch/attach response: java-debug never sends `initialized`
-- for "Run" (noDebug) sessions, so event_initialized would never fire.
local function on_start(session, err)
  if err then return end
  if session.term_buf then show_console(session.term_buf) end
  if session.config.noDebug then
    dapui.close()
  else
    dapui.open { reset = true }
  end
  vim.notify(
    (session.config.noDebug and '▶ Running ' or ' Debugging ') .. session.config.name:gsub('^%a+ ', '')
      .. '\nOutput: console at the bottom  (<leader>dc toggles it)',
    vim.log.levels.INFO,
    { title = session.config.type == 'coreclr' and '.NET' or 'Java' }
  )
end
dap.listeners.after.launch['dapui_config'] = on_start
dap.listeners.after.attach['dapui_config'] = on_start
-- When the program ends, hide the debugger panels but keep the console so the
-- output stays readable.
local function on_end() dapui.close() end
dap.listeners.before.event_terminated['dapui_config'] = on_end
dap.listeners.before.event_exited['dapui_config'] = on_end

-- Install golang specific config
require('dap-go').setup {
  delve = {
    -- On Windows delve must be run attached or it crashes.
    -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
    detached = vim.fn.has 'win32' == 0,
  },
}
