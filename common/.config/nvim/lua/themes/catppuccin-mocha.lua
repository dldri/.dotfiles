return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000, -- Ensure it loads early for themes
  config = function()
    require('catppuccin').setup {
      flavour = 'mocha', -- Set Mocha as the default flavour
      transparent_background = false, -- Customize as needed
      term_colors = true,
      styles = {
        comments = {},
      },
      color_overrides = {
        mocha = {
          base = '#000000',
        },
      },
      integrations = {
        cmp = true, -- For nvim-cmp (included in nvim-kickstart)
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        notify = true,
        mini = true,
        mason = true,
        treesitter = true,
      },
    }
    -- Apply the colorscheme
    vim.cmd.colorscheme 'catppuccin-mocha'
  end,
}
