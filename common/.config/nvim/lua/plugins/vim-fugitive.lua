return {
  'tpope/vim-fugitive',
  event = 'VimEnter',
  keys = {
    { '<leader>gs', '<cmd>G<CR>', desc = 'git [s]tatus' },
    { '<leader>gd', '<cmd>Gdiffsplit<CR>', desc = 'git [d]iff' },
    { '<leader>gB', '<cmd>G blame<CR>', desc = 'git [B]lame' },
    { '<leader>gl', '<cmd>G lg<CR>', desc = 'git [l]og' },
    { '<leader>gb', '<cmd>G branch<CR>', desc = 'git [b]ranch' },
  },
  config = function()
    local Dldri_Fugitive = vim.api.nvim_create_augroup('Dldri_Fugitive', {})
    local autocmd = vim.api.nvim_create_autocmd

    autocmd('FileType', {
      group = Dldri_Fugitive,
      pattern = 'fugitive*',
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local opts = { buffer = bufnr, remap = false }

        opts.desc = 'git [f]etch'
        vim.keymap.set('n', '<leader>gf', function()
          vim.cmd.Git 'fetch'
        end, opts)

        opts.desc = 'git [p]ull'
        vim.keymap.set('n', '<leader>gP', function()
          vim.cmd.Git 'pull'
        end, opts)

        opts.desc = 'git [p]ush'
        vim.keymap.set('n', '<leader>gp', function()
          vim.cmd.Git 'push'
        end, opts)

        opts.desc = 'git [c]ommit'
        vim.keymap.set('n', '<leader>gc', function()
          vim.cmd.Git 'commit'
        end, opts)
      end,
    })

    autocmd('User', {
      group = Dldri_Fugitive,
      pattern = 'FugitivePager',
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local opts = { buffer = bufnr, remap = false }

        opts.desc = 'Delete branch under cursor'
        vim.keymap.set('n', 'X', function()
          local branch = vim.fn.expand '<cfile>'
          vim.ui.input({ prompt = 'Delete branch ' .. branch .. '? (y/n): ' }, function(input)
            if input and input:lower() == 'y' then
              vim.cmd.Git('branch -D ' .. branch)
              vim.cmd 'bdelete'
              vim.cmd.Git 'branch'
            else
              vim.notify('Branch deletion cancelled', vim.log.levels.INFO)
            end
          end)
        end, opts)

        opts.desc = 'Checkout branch under cursor'
        vim.keymap.set('n', '<CR>', function()
          local branch = vim.fn.expand '<cfile>'
          vim.cmd.Git('checkout ' .. branch)
          vim.cmd 'bdelete'
        end, opts)

        opts.desc = 'Create a new branch'
        vim.keymap.set('n', 'cb<Space>', function()
          vim.ui.input({ prompt = 'Enter new branch name: ' }, function(input)
            vim.cmd.Git('branch ' .. input)
            vim.cmd 'bdelete'
            vim.cmd.Git 'branch'
          end)
        end, opts)
      end,
    })
  end,
}
