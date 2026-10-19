-- lua/custom/plugins/doc.lua
-- Interactive documentation and keymap lookup inside Neovim via Telescope

local ok, telescope = pcall(require, 'telescope')
if not ok then return end

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local previewers = require 'telescope.previewers'
local entry_display = require 'telescope.pickers.entry_display'

local function load_docs()
  local data_path = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'docs_data.json')
  local f = io.open(data_path, 'r')
  if not f then return {} end
  local content = f:read '*a'
  f:close()
  local ok_json, data = pcall(vim.json.decode, content)
  return ok_json and data or {}
end

local function doc_picker(opts)
  opts = opts or {}
  local docs = load_docs()
  if #docs == 0 then
    vim.notify('No documentation entries found in docs_data.json', vim.log.levels.WARN)
    return
  end

  local displayer = entry_display.create {
    separator = ' ',
    items = {
      { width = 20 },
      { width = 20 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    return displayer {
      { entry.value.key, 'DiagnosticOk' },
      { '[' .. entry.value.category .. ']', 'Comment' },
      entry.value.name,
    }
  end

  pickers
    .new(opts, {
      prompt_title = 'Interactive Neovim Documentation (Keymaps & Features)',
      finder = finders.new_table {
        results = docs,
        entry_maker = function(entry)
          local search_text = string.format(
            '%s %s %s %s %s %s',
            entry.key or '',
            entry.name or '',
            entry.category or '',
            entry.desc or '',
            entry.detail or '',
            entry.keywords or ''
          )
          return {
            value = entry,
            display = make_display,
            ordinal = search_text,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      previewer = previewers.new_buffer_previewer {
        title = 'Keymap & Workflow Details',
        define_preview = function(self, entry)
          local item = entry.value
          local mode_map = {
            n = 'NORMAL',
            i = 'INSERT',
            v = 'VISUAL',
            x = 'VISUAL',
            t = 'TERMINAL',
            ['n, v'] = 'NORMAL / VISUAL',
            ['n, t'] = 'NORMAL / TERMINAL',
          }
          local mode_badge = mode_map[item.mode] or string.upper(item.mode or 'NORMAL')

          local lines = {
            string.format('KEY COMBINATION: %s', item.key),
            string.format('MODE:            %s', mode_badge),
            string.format('CATEGORY:        %s', item.category),
            string.format('FEATURE:         %s', item.name),
            string.rep('─', 50),
            'DESCRIPTION:',
            '  ' .. item.desc,
            '',
            'HOW TO USE & DETAILS:',
          }

          -- Wrap or indent detail lines
          local detail = item.detail or ''
          for line in detail:gmatch '[^\r\n]+' do
            table.insert(lines, '  ' .. line)
          end

          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.bo[self.state.bufnr].filetype = 'markdown'
        end,
      },
      attach_mappings = function(prompt_bufnr, map)
        local actions = require 'telescope.actions'
        local action_state = require 'telescope.actions.state'

        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection.value then
            vim.notify(
              string.format('[%s] %s: %s', selection.value.key, selection.value.name, selection.value.desc),
              vim.log.levels.INFO,
              { title = 'Neovim Doc' }
            )
          end
        end)
        return true
      end,
    })
    :find()
end

-- Keymap to trigger documentation picker
vim.keymap.set('n', '<leader>?', function() doc_picker() end, { desc = 'Interactive [?] Documentation' })

-- User command :Doc [query]
vim.api.nvim_create_user_command('Doc', function(opts)
  if opts.args and opts.args ~= '' then
    doc_picker { default_text = opts.args }
  else
    doc_picker()
  end
end, { nargs = '?', desc = 'Search interactive Neovim documentation and keybindings' })
