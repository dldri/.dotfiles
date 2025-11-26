-- Highlight todo, notes, etc in comments
return {
  'folke/todo-comments.nvim',
  event = 'VimEnter',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    signs = true,

    vim.keymap.set('n', '<leader>tt', '<cmd>TodoTelescope<CR>', {
      desc = 'Open [T]ODOs in [T]elescope',
      noremap = true,
      silent = true,
    }),
  },
}
