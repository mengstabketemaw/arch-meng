-- Render markdown in the buffer: headings, code blocks, tables, checkboxes, callouts.
-- The cursor line is shown as raw markdown so it can be edited normally.
vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {
  file_types = { 'markdown' },
  completions = { lsp = { enabled = true } },
  code = { sign = false, width = 'block', right_pad = 1 },
  heading = { sign = false },
}

vim.keymap.set('n', '<leader>tm', '<cmd>RenderMarkdown toggle<cr>', { desc = '[T]oggle [M]arkdown render' })
