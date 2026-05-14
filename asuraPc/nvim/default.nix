# Neovim — Catppuccin “rice” (bufferline, lualine, nvim-tree, treesitter, gitsigns)
{ pkgs, ... }:

let
  assetsDir = toString ../assets;
  lua =
    # lua
    ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "
      vim.g.asura_assets = "${assetsDir}"
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.signcolumn = "yes"
      vim.opt.cursorline = true
      vim.opt.termguicolors = true
      vim.opt.mouse = "a"
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.splitbelow = true
      vim.opt.splitright = true
      vim.opt.undofile = true
      vim.opt.wrap = false
      vim.opt.scrolloff = 6

      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        integrations = {
          treesitter = true,
          native_lsp = { enabled = true },
          gitsigns = true,
          nvimtree = true,
          bufferline = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")

      require("nvim-tree").setup({
        view = { width = 32, side = "left" },
        renderer = { icons = { show = { git = true, folder = true, file = true, folder_arrow = true } } },
      })
      vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })

      require("bufferline").setup({
        options = {
          mode = "buffers",
          separator_style = "slant",
          diagnostics = "nvim_diagnostic",
          always_show_bufferline = true,
        },
      })

      require("lualine").setup({
        options = {
          theme = "catppuccin",
          icons_enabled = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })

      require("gitsigns").setup({ current_line_blame = false })

      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent = { enable = true },
      })

      require("image").setup({
        backend = "kitty",
        processor = "magick_cli",
        max_height_window_percentage = 48,
      })

      vim.api.nvim_create_user_command("AsuraAssets", function()
        vim.notify("Asura image assets: " .. vim.g.asura_assets, vim.log.levels.INFO)
      end, { desc = "Print Nix-managed asset directory" })

      vim.api.nvim_create_user_command("AsuraImage", function(opts)
        local name = vim.trim(opts.args or "")
        if name == "" then
          vim.notify("Usage: AsuraImage <filename>  (under " .. vim.g.asura_assets .. ")", vim.log.levels.WARN)
          return
        end
        local path = vim.g.asura_assets .. "/" .. name
        if vim.fn.filereadable(path) == 1 then
          vim.cmd("edit " .. vim.fn.fnameescape(path))
        else
          vim.notify("Not found: " .. path, vim.log.levels.ERROR)
        end
      end, {
        nargs = "?",
        complete = function()
          local dir = vim.g.asura_assets
          local out = {}
          for _, f in ipairs(vim.fn.readdir(dir) or {}) do
            if f:match("%.png$") or f:match("%.jpe?g$") or f:match("%.webp$") or f:match("%.gif$") then
              table.insert(out, f)
            end
          end
          return out
        end,
      })
    '';
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = false;
    withPython3 = true;
    withRuby = false;
    extraPackages = [ pkgs.imagemagick ];
    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim
      nvim-web-devicons
      nvim-tree-lua
      bufferline-nvim
      lualine-nvim
      gitsigns-nvim
      image-nvim
      (nvim-treesitter.withPlugins (p: [
        p.bash
        p.c
        p.cpp
        p.css
        p.fish
        p.gitignore
        p.html
        p.javascript
        p.json
        p.lua
        p.markdown
        p.markdown_inline
        p.nix
        p.python
        p.regex
        p.rust
        p.toml
        p.typescript
        p.vim
        p.yaml
      ]))
    ];
    initLua = lua;
  };
}
