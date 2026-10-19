-- vim: ts=2 sts=2 sw=2 et

-- [[ Leader key ]]
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- [[ Setting options ]]
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.backup = false
vim.opt.completeopt = "menu,menuone,preview,noselect"
vim.opt.cursorline = true
vim.opt.encoding = "utf8"
vim.opt.expandtab = true
vim.opt.fileencoding = "utf8"
vim.opt.formatoptions = "tcrqnb"
vim.opt.gdefault = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.inccommand = "split"
vim.opt.incsearch = true
vim.opt.lazyredraw = true -- hint
vim.opt.list = true
vim.opt.listchars = "extends:»,precedes:«,tab:→ ,trail:·,leadmultispace:╎ "
vim.opt.modeline = false
vim.opt.modelineexpr = false
vim.opt.modelines = 2
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 5
vim.opt.shell = vim.fn.executable("fish") == 1 and "fish" or "bash"
vim.opt.shiftwidth = 2
vim.opt.showcmd = true
vim.opt.showmode = true
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.softtabstop = 2
vim.opt.spell = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.syntax = "on"
vim.opt.tabstop = 2
vim.opt.termguicolors = true
vim.opt.timeout = true
vim.opt.timeoutlen = 300
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.undofile = true
vim.opt.updatetime = 100
vim.opt.winborder = "bold"
vim.opt.wrap = true
vim.opt.writebackup = false

vim.keymap.set("n", "<C-c>", "<cmd>nohlsearch<CR>")

-- [[ Word wrap aware movement ]]
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Diagnostic settings ]]
vim.diagnostic.config({ virtual_text = true })
vim.keymap.set("n", "<ESC><ESC>", "<CMD>cclose<CR>")

-- [[ Buffer movement ]]
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Move half a page down (and center)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Move half a page up (and center)" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next (and center)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous (and center)" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines (and stay)" })
vim.keymap.set("n", "<leader>x", ":bdelete<CR>")

-- [[ Yanking, pasting, deleting ]]
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste (without yanking)" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "v", "x" }, "<leader>d", '"_d', { desc = "Delete (without yanking)" })

local yank_highlight_group = vim.api.nvim_create_augroup("YankHighlightGroup", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = yank_highlight_group,
  pattern = "*",
})

-- [[ Buffer freshness ]]
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { "*" },
})

-- [[ Language Server Protocol keymap ]]
vim.keymap.set("i", "<C-space>", vim.lsp.completion.get)
vim.keymap.set("n", "<C-space>", vim.lsp.buf.code_action)
vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, { desc = "LSP Format" })

-- [[ Language Server Protocol autocompletion and formatting ]]
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my.lsp", {}),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
    -- add 'gd' as 'go to definition' shortcut
    vim.api.nvim_buf_set_keymap(
      args.buf,
      "n",
      "gd",
      "<cmd>lua vim.lsp.buf.definition()<CR>",
      { noremap = true, silent = true, desc = "LSP Go to Definition" }
    )
  end,
})

-- [[ Language Server Protocol inline completion ]]
vim.lsp.inline_completion.enable()
vim.keymap.set("i", "<Tab>", function()
  if not vim.lsp.inline_completion.get() then
    return "<Tab>"
  end
  if vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-e>")
  end
end, {
  expr = true,
  replace_keycodes = true,
  desc = "Get the current inline completion",
})

-- [[ Language Server Protocol configuration ]]
vim.lsp.enable({
  "bashls",
  "biome",
  "clangd",
  "copilot",
  "fish_lsp",
  "graphql",
  "helm_ls",
  "lua_ls",
  "marksman",
  -- "ruff",
  -- "sourcekit",
  "tsgo",
  "ty",
  "vale_ls",
  "yamlls",
  "zizmor",
  "zls",
})

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".git" },
  settings = {
    Lua = {
      completion = {
        callSnippet = "Replace",
      },
      runtime = {
        version = "LuaJIT",
      },
      workspace = {
        checkThirdParty = false,
        library = {
          "${3rd}/luv/library",
          unpack(vim.api.nvim_get_runtime_file("", true)),
        },
      },
    },
  },
})

vim.lsp.config("yamlls", {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml" },
  root_markers = { ".git" },
  settings = {
    yaml = {
      format = {
        enable = true,
      },
      redhat = {
        telemetry = {
          enabled = false,
        },
      },
      schemas = {
        kubernetes = "k8s-*.{yml,yaml}",
        ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
        ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
        ["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
        ["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
      },
    },
  },
})

-- [[ Package manager ]]
vim.pack.add({
  -- Look and feel
  { src = "https://github.com/catppuccin/nvim", version = "v2.0.0" },
  { src = "https://github.com/j-hui/fidget.nvim", version = "v2.0.0" },
  { src = "https://github.com/lewis6991/gitsigns.nvim", version = "v2.1.0" },
  -- LSP related
  { src = "https://github.com/mason-org/mason.nvim", version = "v2.3.1" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim", version = "v2.3.0" },
  { src = "https://github.com/neovim/nvim-lspconfig", version = "v2.11.0" },
  { src = "https://github.com/arborist-ts/arborist.nvim", version = "v0.7.1" },
  -- Utilities
  { src = "https://github.com/nvim-lua/plenary.nvim", version = "v0.1.4" },
  { src = "https://github.com/stevearc/oil.nvim", version = "v2.16.0" },
  { src = "https://github.com/stevearc/conform.nvim", version = "v9.1.0" },
}, {
  load = function(data)
    -- Load only the packages needed to configure the editor itself.  The rest
    -- stay off 'runtimepath' until their command or keymap is used.
    if
      vim.tbl_contains({
        "nvim",
        "fidget.nvim",
        "gitsigns.nvim",
        "mason.nvim",
        "mason-lspconfig.nvim",
        "nvim-lspconfig",
        "arborist.nvim",
      }, data.spec.name)
    then
      vim.cmd.packadd(data.spec.name)
    end
  end,
})

-- Keep infrequently used UI plugins out of the startup path. This uses only
-- Neovim's native package loader; `packadd` makes a package available on demand.
local lazy_loaded = {}
local function lazy_load(name)
  if not lazy_loaded[name] then
    vim.cmd.packadd(name)
    lazy_loaded[name] = true
  end
end

-- [[ Package configuration: catppuccin ]]
vim.cmd.colorscheme("catppuccin-mocha")

-- [[ Package configurations ]]
require("arborist").setup()
require("fidget").setup({})
require("gitsigns").setup({
  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end)

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end)

    -- Actions
    map("n", "<leader>hs", gitsigns.stage_hunk)
    map("n", "<leader>hr", gitsigns.reset_hunk)

    map("v", "<leader>hs", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end)

    map("v", "<leader>hr", function()
      gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end)

    map("n", "<leader>hS", gitsigns.stage_buffer)
    map("n", "<leader>hR", gitsigns.reset_buffer)
    map("n", "<leader>hp", gitsigns.preview_hunk)
    map("n", "<leader>hi", gitsigns.preview_hunk_inline)

    map("n", "<leader>hb", function()
      gitsigns.blame_line({ full = true })
    end)

    map("n", "<leader>hd", gitsigns.diffthis)

    map("n", "<leader>hD", function()
      gitsigns.diffthis("~")
    end)

    map("n", "<leader>hQ", function()
      gitsigns.setqflist("all")
    end)
    map("n", "<leader>hq", gitsigns.setqflist)

    -- Toggles
    map("n", "<leader>tb", gitsigns.toggle_current_line_blame)
    map("n", "<leader>tw", gitsigns.toggle_word_diff)

    -- Text object
    map({ "o", "x" }, "ih", gitsigns.select_hunk)
  end,
})

require("mason").setup({})
require("mason-lspconfig").setup({
  ensure_installed = { "clangd", "lua_ls", "rust_analyzer" },
})

-- [[ Basic quickfix list navigation ]]
vim.keymap.set("n", "<CR><CR>", function()
  vim.ui.input({ prompt = "File find: " }, function(query)
    if not query or query == "" then
      return
    end

    local command = vim.fn.executable("fd") == 1 and { "fd", "--type", "f", "--color", "never", "--glob", query }
      or { "find", ".", "-type", "f", "-not", "-path", "./.git/*" }

    vim.system(command, { text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 and result.code ~= 1 then
          vim.notify(result.stderr ~= "" and result.stderr or "Search command failed", vim.log.levels.ERROR)
          return
        end

        local lines = vim.split(result.stdout, "\n", { plain = true, trimempty = true })
        local items = {}
        if command[1] ~= "fd" then
          lines = vim.tbl_filter(function(filename)
            return filename:find(query, 1, true) ~= nil
          end, lines)
        end
        for _, filename in ipairs(lines) do
          items[#items + 1] = { filename = filename, lnum = 1, text = filename }
        end

        vim.fn.setqflist({}, " ", { title = "Find files: " .. query, items = items })
        if #items > 0 then
          vim.cmd("copen")
        else
          vim.notify("No matches", vim.log.levels.INFO)
        end
      end)
    end)
  end)
end, { desc = "File find in quickfix" })

vim.keymap.set("n", "<leader><leader>", function()
  vim.ui.input({ prompt = "File grep: " }, function(query)
    if not query or query == "" then
      return
    end

    local command = vim.fn.executable("rg") == 1 and { "rg", "--vimgrep", "--color", "never", query }
      or { "grep", "-RIn", "--exclude-dir=.git", "--", query, "." }
    local errorformat = vim.fn.executable("rg") == 1 and "%f:%l:%c:%m" or "%f:%l:%m"

    vim.system(command, { text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 and result.code ~= 1 then
          vim.notify(result.stderr ~= "" and result.stderr or "Search command failed", vim.log.levels.ERROR)
          return
        end

        local lines = vim.split(result.stdout, "\n", { plain = true, trimempty = true })
        local items = vim.fn.getqflist({ lines = lines, efm = errorformat }).items
        vim.fn.setqflist({}, " ", { title = "Grep: " .. query, items = items })
        if #items > 0 then
          vim.cmd("copen")
        else
          vim.notify("No matches", vim.log.levels.INFO)
        end
      end)
    end)
  end)
end, { desc = "File grep in quickfix" })

vim.keymap.set("n", "<backspace><backspace>", function()
  lazy_load("oil.nvim")
  require("oil").setup({
    keymaps = {
      ["<backspace>"] = { "actions.parent", mode = "n" },
    },
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name)
        return name:match("^.git$")
      end,
    },
  })
  vim.cmd.Oil()
end)

-- [[ Conform ]]
local conform_ready = false
local function lazy_conform()
  lazy_load("conform.nvim")
  if not conform_ready then
    require("conform").setup({
      formatters_by_ft = {
        javascript = { "biome" },
        markdown = { "mdsf" },
        lua = { "stylua" },
        odin = { "odinfmt" },
        rust = { "rustfmt" },
        typescript = { "biome" },
        zig = { "zigfmt" },
      },
    })
    conform_ready = true
  end
end

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    lazy_conform()
    require("conform").format({ bufnr = args.buf })
  end,
})
