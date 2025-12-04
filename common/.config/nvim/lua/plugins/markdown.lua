return {
  {
    'obsidian-nvim/obsidian.nvim',
    version = '*', -- recommended, use latest release instead of latest commit
    ft = 'markdown',
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   "BufReadPre path/to/my-vault/*.md",
    --   "BufNewFile path/to/my-vault/*.md",
    -- },
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false, -- this will be removed in the next major release
      workspaces = {
        {
          name = 'life',
          path = '~/notes/',
        },
      },
      ui = {
        enable = false,
      },

      note_id_func = function(title)
        local slug = title
          :gsub('^%s*(.-)%s*$', '%1') -- trim
          :gsub('%s+', '-') -- spaces → hyphens
          :gsub('[^%w%-]', '') -- remove non-alphanum/hyphen
          :gsub('-+', '-') -- collapse hyphens
          :gsub('^-+', '') -- no leading hyphens
          :gsub('-+$', '') -- no trailing hyphens
          :lower()
        if slug == '' then
          slug = require('obsidian.builtin').zettel_id() -- safety for empty slugs
        end
        return slug
      end,

      frontmatter = {
        enabled = true,
        sort = { 'id', 'aliases', 'tags' },
        func = function(note)
          local fm = require('obsidian.builtin').frontmatter(note)
          if note.title and fm.aliases then
            fm.aliases = vim.tbl_filter(function(a)
              return a ~= note.title
            end, fm.aliases)
          end
          return fm
        end,
      },

      callbacks = {
        enter_note = function(note)
          vim.keymap.set('n', '<leader>bl', '<cmd>Obsidian backlinks<cr>', {
            buffer = note.bufnr,
            desc = 'Show backlinks',
          })
        end,
      },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },
}
