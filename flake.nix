{
  description = "Neovim for koozz";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    plugin-catppuccin = { url = "git+https://github.com/catppuccin/nvim?rev=605b4603797de970e9f3a4238c199c850da03186"; flake = false; };
    plugin-fidget = { url = "git+https://github.com/j-hui/fidget.nvim?rev=e1a07a5e46fb65a45a0c76870140bd2d16a73ebf"; flake = false; };
    plugin-gitsigns = { url = "git+https://github.com/lewis6991/gitsigns.nvim?rev=a462f416e2ce4744531c6256252dee99a7d34a83"; flake = false; };
    plugin-mason = { url = "git+https://github.com/mason-org/mason.nvim?rev=2a6940af80375532e5e9e7c1f2fc6319a1b7a69d"; flake = false; };
    plugin-mason-lspconfig = { url = "git+https://github.com/mason-org/mason-lspconfig.nvim?rev=a5671269a1ddfa7790cdf97c14e600e269da550f"; flake = false; };
    plugin-nvim-lspconfig = { url = "git+https://github.com/neovim/nvim-lspconfig?rev=b89138d9af0a96e6048e202a15765fc6b6416bd4"; flake = false; };
    plugin-arborist = { url = "git+https://github.com/arborist-ts/arborist.nvim?rev=fdeef56c2840c6772b9f68c5774ed87e9340ec7d"; flake = false; };
    plugin-plenary = { url = "git+https://github.com/nvim-lua/plenary.nvim?rev=50012918b2fc8357b87cff2a7f7f0446e47da174"; flake = false; };
    plugin-oil = { url = "git+https://github.com/stevearc/oil.nvim?rev=17c0a8faaf48298a0c0cfb0d757c0eaee4ff7a32"; flake = false; };
    plugin-conform = { url = "git+https://github.com/stevearc/conform.nvim?rev=3543d000dafbc41cc7761d860cfdb24e82154f75"; flake = false; };
  };

  outputs = inputs @ {
    nixpkgs,
    flake-utils,
    ...
  }: let
    systems = builtins.attrNames nixpkgs.legacyPackages;

    neovim-overlay = _final: prev: let
      mkPlugin = pname: version: src: prev.vimUtils.buildVimPlugin {
        inherit pname version src;
        # The module check reports optional and generated modules as missing.
        doCheck = false;
      };
      plugins = [
        (mkPlugin "catppuccin" "2.0.0" inputs.plugin-catppuccin)
        (mkPlugin "fidget.nvim" "2.0.0" inputs.plugin-fidget)
        (mkPlugin "gitsigns.nvim" "2.1.0" inputs.plugin-gitsigns)
        (mkPlugin "mason.nvim" "2.3.1" inputs.plugin-mason)
        (mkPlugin "mason-lspconfig.nvim" "2.3.0" inputs.plugin-mason-lspconfig)
        (mkPlugin "nvim-lspconfig" "2.11.0" inputs.plugin-nvim-lspconfig)
        (mkPlugin "arborist.nvim" "0.7.1" inputs.plugin-arborist)
        (mkPlugin "plenary.nvim" "0.1.4" inputs.plugin-plenary)
        (mkPlugin "oil.nvim" "2.16.0" inputs.plugin-oil)
        (mkPlugin "conform.nvim" "9.1.0" inputs.plugin-conform)
      ];
      nvim = prev.wrapNeovim prev.neovim-unwrapped {
        configure = {
          customRC = ''
            lua << EOF
            vim.cmd.packadd("catppuccin")
            vim.cmd.packadd("plenary.nvim")
            -- Use Nix packages but keep init.lua's load callback.
            vim.pack.add = function(specs, opts)
              if opts and opts.load then
                for _, spec in ipairs(specs) do
                  opts.load({ spec = { name = spec.src:match("([^/]+)$") } })
                end
              end
            end
            ${builtins.readFile ./init.lua}
            EOF
          '';
          packages.myVimPackage.opt = plugins;
        };
      };
    in {
      nvim-pkg = nvim;
      nvim-dev = nvim;
    };
  in
    flake-utils.lib.eachSystem systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          neovim-overlay
        ];
      };
      shell = pkgs.mkShell {
        name = "nvim-devShell";
        buildInputs = with pkgs; [
          # Tools for Lua and Nix development, useful for editing files in this repo
          lua-language-server
          nil
          stylua
          luajitPackages.luacheck
          nvim-dev
        ];
      };
    in {
      packages = rec {
        default = nvim;
        nvim = pkgs.nvim-pkg;
      };
      devShells = {
        default = shell;
      };
    })
    // {
      # You can add this overlay to your NixOS configuration
      overlays.default = neovim-overlay;
    };
}
