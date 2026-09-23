local function resize_mode()
  local opts = { buffer = true, silent = true }

  vim.notify('Resize mode: ↑ ↓ ← → | Esc to exit')

  vim.keymap.set('n', '<Up>', ':resize +2<CR>', opts)
  vim.keymap.set('n', '<Down>', ':resize -2<CR>', opts)
  vim.keymap.set('n', '<Left>', ':vertical resize -2<CR>', opts)
  vim.keymap.set('n', '<Right>', ':vertical resize +2<CR>', opts)

  vim.keymap.set('n', '<Esc>', function()
    vim.keymap.del('n', '<Up>', { buffer = true })
    vim.keymap.del('n', '<Down>', { buffer = true })
    vim.keymap.del('n', '<Left>', { buffer = true })
    vim.keymap.del('n', '<Right>', { buffer = true })
    vim.keymap.del('n', '<Esc>', { buffer = true })

    vim.notify('Exited resize mode')
  end, opts)
end

vim.keymap.set('n', '<leader>tr', resize_mode, {
  desc = 'Enter resize mode',
})
