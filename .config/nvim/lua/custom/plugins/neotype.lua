vim.pack.add({
  "https://github.com/rodolfo-arg/neotype",
})


require("neotype").setup({
  auto_start_insert = true,
  auto_skip_indent_on_enter = true,
  tab_consumes_leading_indent = true,
  allow_backspace = true,
})
