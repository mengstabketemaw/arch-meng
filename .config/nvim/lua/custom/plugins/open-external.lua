-- Open binary files (images, video, audio, pdf, office docs) in the system default
-- application via xdg-open instead of loading the raw bytes into a buffer.
-- Works for anything that edits a file: :e, nvim-tree, telescope, `nvim foo.png`, ...

local extensions = {
  -- images
  'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'tiff', 'tif', 'ico', 'avif', 'heic',
  -- video
  'mp4', 'mkv', 'webm', 'mov', 'avi', 'flv', 'wmv', 'm4v',
  -- audio
  'mp3', 'flac', 'wav', 'ogg', 'm4a', 'opus', 'aac',
  -- documents
  'pdf', 'docx', 'xlsx', 'pptx', 'odt', 'ods', 'odp',
}

-- Autocmd patterns are case sensitive, so match both `.png` and `.PNG`
local patterns = {}
for _, ext in ipairs(extensions) do
  table.insert(patterns, '*.' .. ext)
  table.insert(patterns, '*.' .. ext:upper())
end

vim.api.nvim_create_autocmd('BufReadCmd', {
  group = vim.api.nvim_create_augroup('custom-open-external', { clear = true }),
  pattern = patterns,
  callback = function(ev)
    vim.ui.open(vim.fn.fnamemodify(ev.match, ':p'))

    -- Drop the empty placeholder buffer once the edit command has finished
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then vim.api.nvim_buf_delete(ev.buf, { force = true }) end
    end)
  end,
})
