{
  description = "My custom Neovim setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    ### Theme/UI
    plugin-nord = { url = "github:nordtheme/vim"; flake = false; };
    plugin-lualine = { url = "github:nvim-lualine/lualine.nvim"; flake = false; };

    ### Utilities
    plugin-plenary = { url = "github:nvim-lua/plenary.nvim"; flake = false; };
    plugin-popup = { url = "github:nvim-lua/popup.nvim"; flake = false; };
    plugin-telescope = { url = "github:nvim-telescope/telescope.nvim"; flake = false; };
    plugin-vim-commentary = { url = "github:tpope/vim-commentary"; flake = false; };
    plugin-vim-surround = { url = "github:tpope/vim-surround"; flake = false; };

    ### Copilot
    plugin-copilot = { url = "github:zbirenbaum/copilot.lua"; flake = false; };
    plugin-copilot-cmp = { url = "github:zbirenbaum/copilot-cmp"; flake = false; };

    ### Completion
    plugin-nvim-lspconfig = { url = "github:neovim/nvim-lspconfig"; flake = false; };
    plugin-cmp-nvim-lsp = { url = "github:hrsh7th/cmp-nvim-lsp"; flake = false; };
    plugin-cmp-buffer = { url = "github:hrsh7th/cmp-buffer"; flake = false; };
    plugin-cmp-path = { url = "github:hrsh7th/cmp-path"; flake = false; };
    plugin-cmp-cmdline = { url = "github:hrsh7th/cmp-cmdline"; flake = false; };
    plugin-nvim-cmp = { url = "github:hrsh7th/nvim-cmp"; flake = false; };

    plugin-nvim-snippy = { url = "github:dcampos/nvim-snippy"; flake = false; };
    plugin-cmp-snippy = { url = "github:dcampos/cmp-snippy"; flake = false; };

    plugin-cmp-nvim-lua = { url = "github:hrsh7th/cmp-nvim-lua"; flake = false; };
    plugin-cmp-nvim-lsp-signature-help = { url = "github:hrsh7th/cmp-nvim-lsp-signature-help"; flake = false; };

    plugin-cmp-treesitter = { url = "github:ray-x/cmp-treesitter"; flake = false; };

    ### Language support
    plugin-nvim-treesitter = { url = "github:nvim-treesitter/nvim-treesitter"; flake = false; };
    plugin-go = { url = "github:fatih/vim-go"; flake = false; };
    plugin-poetry = { url = "github:karloskar/poetry-nvim"; flake = false; };
    plugin-rust = { url = "github:rust-lang/rust.vim"; flake = false; };
    plugin-terraform = { url = "github:hashivim/vim-terraform"; flake = false; };
    plugin-vim-rego = { url = "github:tsandall/vim-rego"; flake = false; };
    plugin-zig = { url = "github:ziglang/zig.vim"; flake = false; };

    ### Formatters/linters
    plugin-editorconfig = { url = "github:editorconfig/editorconfig-vim"; flake = false; };
    plugin-prettier = { url = "github:prettier/vim-prettier"; flake = false; };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pluginOverlay = final: prev:
          let
            inherit (prev.vimUtils) buildVimPluginFrom2Nix;
            plugins = builtins.filter
              (s: (builtins.match "plugin-.*" s) != null)
              (builtins.attrNames inputs);
            plugName = input:
              builtins.substring
                (builtins.stringLength "plugin-")
                (builtins.stringLength input)
                input;
            buildPlug = name: buildVimPluginFrom2Nix {
              pname = plugName name;
              version = "HEAD";
              src = builtins.getAttr name inputs;
            };
          in
          {
            neovimPlugins = builtins.listToAttrs (map
              (plugin: {
                name = plugName plugin;
                value = buildPlug plugin;
              })
              plugins);
          };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            pluginOverlay
          ];
        };

        neovimBuilder =
          { initLua ? ""
          , viAlias ? true
          , vimAlias ? true
          , start ? builtins.attrValues pkgs.neovimPlugins
          , opt ? [ ]
          , debug ? false
          }:
          let
            myNeovimUnwrapped = pkgs.neovim-unwrapped.overrideAttrs (prev: {
              propagatedBuildInputs = with pkgs; [ pkgs.stdenv.cc.cc.lib ];
            });
            myTreesitterParsers = ".config/nvim/parsers";
          in
          pkgs.wrapNeovim myNeovimUnwrapped {
            inherit viAlias;
            inherit vimAlias;
            configure = {
              customRC = ''
                " Impure tree-sitter hack
                call mkdir($HOME . "/${myTreesitterParsers}", "p", 0700)
                set runtimepath^=${myTreesitterParsers}"
                " Add some tools to the runtime path
                set runtimepath^=${pkgs.yarn}/bin
                set runtimepath^=${pkgs.terraform}/bin
                set runtimepath^=${pkgs.shfmt}/bin
                set runtimepath^=${pkgs.poetry}/bin
                set runtimepath^=${pkgs.nodejs}/bin
                set runtimepath^=${pkgs.nixpkgs-fmt}/bin
                set runtimepath^=${pkgs.go}/bin
                set runtimepath^=${pkgs.fish}/bin
                set runtimepath^=${pkgs.cargo}/bin
                " Load configuration from init.lua
                lua <<EOF
                ${initLua}
                -- Point treesitter to the parsers
                require ("nvim-treesitter.configs").setup({
                  parser_install_dir = "~/${myTreesitterParsers}",
                  auto_install = true,
                  highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                  },
                });
                EOF
              '';
              packages.myVimPackage = with pkgs.neovimPlugins; {
                start = start;
                opt = opt;
              };
            };
          };
      in
      rec {
        apps.default = apps.nvim;
        packages.default = packages.customNeovim;

        apps.nvim = {
          type = "app";
          program = "${packages.customNeovim}/bin/nvim";
        };

        packages.customNeovim = neovimBuilder {
          initLua = ''
            ${pkgs.lib.readFile ./init.lua}

            -- lsp_on_attach and lsp_capabilities defined in init.lua
            -- these are configured here because they rely on nixpkgs
            require("lspconfig").bashls.setup({
              cmd = { "${pkgs.nodePackages_latest.bash-language-server}/bin/bash-language-server", "start" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").gopls.setup({
              cmd = { "${pkgs.gopls}/bin/gopls" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").lua_ls.setup({
              cmd = { "${pkgs.sumneko-lua-language-server}/bin/lua-language-server" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
              settings = {
                Lua = {
                  runtime = {
                    version = 'LuaJIT',
                  },
                  diagnostics = {
                    globals = {'vim'},
                  },
                  workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                  },
                  telemetry = {
                    enable = false,
                  },
                },
              },
            });

            require("lspconfig").marksman.setup({
              cmd = { "${pkgs.marksman}/bin/marksman", "server" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").pyright.setup({
              cmd = { "${pkgs.nodePackages_latest.pyright}/bin/pyright", "--stdio" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").rnix.setup({
              cmd = { "${pkgs.rnix-lsp}/bin/rnix-lsp" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").ruff_lsp.setup({
              cmd = { "${pkgs.ruff}/bin/ruff" },
              on_attach = function(client, bufnr)
                -- Disable hover in favor of Pyright
                client.server_capabilities.hoverProvider = false
                lsp_on_attach(client, bufnr)
              end,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").rust_analyzer.setup({
              cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").taplo.setup({
              cmd = { "${pkgs.taplo}/bin/taplo", "lsp", "stdio" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").terraformls.setup({
              cmd = { "${pkgs.terraform-ls}/bin/terraform-ls", "serve" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").tflint.setup({
              cmd = { "${pkgs.tflint}/bin/tflint", "--langserver" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").tsserver.setup({
              cmd = { "${pkgs.nodePackages_latest.typescript-language-server}/bin/typescript-language-server", "--stdio" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").yamlls.setup({
              cmd = { "${pkgs.nodePackages_latest.yaml-language-server}/bin/yaml-language-server", "--stdio" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("lspconfig").zls.setup({
              cmd = { "${pkgs.zls}/bin/zls" },
              on_attach = lsp_on_attach,
              capabilities = lsp_capabilities,
            });

            require("poetry-nvim").setup();
          '';
        };
      }
    );
}
