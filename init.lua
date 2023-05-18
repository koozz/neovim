--[[ Globals ]]
vim.g.mapleader = " "
vim.g.t_Co = 256
vim.g.EditorConfig_exclude_patterns = { "fugitive://.*", "scp://.*" }
vim.g.rustfmt_autosave = 1
vim.g.rustfmt_emit_files = 1
vim.g.rustfmt_fail_silently = 0
vim.g.terraform_fmt_on_save = 1
vim.g.terraform_align = 1

--[[ Options ]]
vim.o.autoindent = true
vim.o.backup = false
vim.o.completeopt = "menu,menuone,preview,noselect,noinsert"
vim.o.cursorline = true
vim.o.encoding = "utf8"
vim.o.expandtab = true
vim.o.fileencoding = "utf8"
vim.o.formatoptions = tcrqnb
vim.o.gdefault = true
vim.o.hlsearch = false
vim.o.ignorecase = true
vim.o.incsearch = true
vim.o.listchars = "eol:↲,extends:»,precedes:«,tab:▸ ,trail:·"
vim.o.modeline = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.scrolloff = 4
vim.o.spell = true
vim.o.spelllang = "en"
vim.o.spellfile = "~/.config/nvim/spell/en.utf-8.add"
vim.o.shell = vim.fn.executable "fish" == 1 and "fish" or "bash"
vim.o.shiftwidth = 4
vim.o.showcmd = true
vim.o.signcolumn = "yes"
vim.o.smartcase = true
vim.o.softtabstop = 4
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.syntax = "on"
vim.o.tabstop = 4
vim.o.termguicolors = true
vim.o.updatetime = 300
vim.o.writebackup = false

--[[ Theme/UI ]]
vim.cmd [[colorscheme nord]]
require("lualine.themes.nord")
require("lualine").setup({
  options = {
    globalstatus = false,
    icons_enabled = false,
    theme = "nord",
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    always_divide_middle = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { "filename" },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" }
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
})

--[[ Telescope ]]
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>b", builtin.buffers, {})
vim.keymap.set("n", "<leader>f", builtin.find_files, {})
vim.keymap.set("n", "<leader>g", builtin.live_grep, {})
vim.keymap.set("n", "<leader>h", builtin.help_tags, {})
vim.keymap.set("n", "<leader>m", builtin.marks, {})
vim.keymap.set("n", "<leader>s", builtin.grep_string, {})
-- vim.keymap.set("n", "<leader>t", builtin.treesitter, {})
vim.keymap.set("n", "<leader>c", builtin.git_commits, {})
vim.keymap.set("n", "<leader>s", builtin.git_status, {})
vim.keymap.set("n", "<leader><space>", function()
  vim.fn.system("git rev-parse --is-inside-work-tree")
  if vim.v.shell_error == 0 then
    require("telescope.builtin").git_files({})
  else
    require("telescope.builtin").find_files({})
  end
end, {})
vim.keymap.set("n", "<backspace><backspace>", builtin.buffers, {})

--[[ Copilot ]]
require("copilot").setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
});
require("copilot_cmp").setup();

--[[ Completion ]]
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require("snippy").expand_snippet(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "copilot" },
    { name = "nvim_lsp" },
    { name = "path" },
    { name = "buffer",  keyword_length = 3 },
    { name = "snippy",  keyword_length = 2 },
  }),
})
cmp.setup.cmdline(":", {
  sources = cmp.config.sources({
    { name = "path" }
  })
})

--[[ Language Server Protocols // configured in flake.nix ]]
---@diagnostic disable-next-line: unused-local
local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities();

---@diagnostic disable-next-line: unused-local, unused-function
local function lsp_on_attach(client, bufnr)
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", "<Cmd>lua vim.lsp.buf.implementation()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-k>", "<Cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>t", "<Cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>r", "<Cmd>lua vim.lsp.buf.rename()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>§", "<Cmd>lua vim.lsp.buf.code_action()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<Cmd>lua vim.lsp.buf.references()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "[d", "<Cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "]d", "<Cmd>lua vim.diagnostic.goto_next()<CR>", opts)

  if client.server_capabilities.documentFormattingProvider then
    vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>=", "<Cmd>lua vim.lsp.buf.format({ async = true })<CR>", opts)
  end
  if client.server_capabilities.documentRangeFormattingProvider then
    vim.api.nvim_buf_set_keymap(bufnr, "v", "<leader>=", "<Cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
  end

  if client.server_capabilities.documentHighlightProvider then
    vim.api.nvim_exec([[
        augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
        ]], false)
  end
end
