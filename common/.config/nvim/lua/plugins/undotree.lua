return {
  'mbbill/undotree',
  config = function()
    local is_linux = vim.fn.has 'unix' == 1

    if is_linux then
      vim.g.undotree_DiffCommand = 'diff'
    else
      vim.g.undotree_DiffCommand = 'FC'
    end

    vim.g.undotree_WindowLayout = 4
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = 'Toggle [U]ndotree' })
  end,
}
