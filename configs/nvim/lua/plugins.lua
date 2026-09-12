-- Settings

-- Automatically install lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Use a protected call so we don't error out on first use
local status_ok, lazy = pcall(require, "lazy")
if not status_ok then
	vim.notify("lazy.nvim failed to load", vim.log.levels.WARN)
	return
end

-- Filetypes for colorizer
local colorizer_fts = {
	"conf",
	"vim",
	"html",
	"css",
	"json",
	"python",
	"javascript",
	"javascriptreact",
	"typescript",
	"typescriptreact",
	"cpp",
	"rust",
	"go",
	"lua",
}

-- Plugin spec

lazy.setup({
	spec = {
		-- Visual

		-- Gruvbox theme
		{
			"ellisonleao/gruvbox.nvim",
			lazy = false,
			priority = 1000,
			config = function()
				require("core.colorscheme")
			end,
		},

		-- Status line
		{
			"nvim-lualine/lualine.nvim",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			event = "VeryLazy",
			config = function()
				require("core.statusline")
			end,
		},

		-- Tabs
		{
			"romgrk/barbar.nvim",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			event = { "BufReadPost", "BufNewFile" },
			config = function()
				require("core.tabs")
			end,
		},

		-- Colorizer
		{
			"catgoose/nvim-colorizer.lua",
			ft = colorizer_fts,
			config = function()
				require("colorizer").setup({ filetypes = colorizer_fts })
			end,
		},

		-- Indentline
		{
			"lukas-reineke/indent-blankline.nvim",
			main = "ibl",
			event = { "BufReadPost", "BufNewFile" },
			config = function()
				require("core.indentline")
			end,
		},

		-- Utilities

		-- NNN File Manager
		{
			"mcchrish/nnn.vim",
			config = function()
				require("core.filemanager")
			end,
		},

		-- Fuzzy search
		{
			"nvim-telescope/telescope.nvim",
			dependencies = {
				"nvim-lua/plenary.nvim",
				{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
				"nvim-telescope/telescope-ui-select.nvim",
			},
			config = function()
				require("core.telescope")
			end,
		},

		-- Git Integration
		{
			"lewis6991/gitsigns.nvim",
			event = { "BufReadPost", "BufNewFile" },
			config = function()
				require("core.gitsigns")
			end,
		},

		-- Multi Cursor
		{
			"mg979/vim-visual-multi",
			init = function()
				vim.g.VM_default_mappings = 0
				vim.g.VM_maps = {
					["Add Cursor Down"] = "<M-S-Down>",
					["Add Cursor Up"] = "<M-S-Up>",
					["Find Under"] = "<C-n>",
				}
			end,
		},

		-- Treesitter integrations

		-- Treesitter
		{
			"nvim-treesitter/nvim-treesitter",
			branch = "main",
			build = ":TSUpdate",
			lazy = false,
			config = function()
				require("core.treesitter")
			end,
		},

		-- Bracket Matchup
		{
			"andymass/vim-matchup",
			event = { "BufReadPost", "BufNewFile" },
			init = function()
				vim.g.matchup_surround_enabled = 1
				vim.g.matchup_matchparen_offscreen = { method = "popup" }
				require("match-up").setup({
					treesitter = { stopline = 500 },
				})
			end,
		},

		-- HTML Autotag and Autorename tags
		{
			"windwp/nvim-ts-autotag",
			ft = {
				"html",
				"javascript",
				"typescript",
				"javascriptreact",
				"typescriptreact",
				"vue",
				"svelte",
				"xml",
			},
			opts = {},
		},

		-- LSP

		-- Server configurations
		{
			"neovim/nvim-lspconfig",
			config = function()
				require("lsp")
			end,
		},

		-- Auto pairs
		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			config = function()
				require("lsp.autopairs")
			end,
		},

		-- Null-ls
		{
			"nvimtools/none-ls.nvim",
			dependencies = { "nvim-lua/plenary.nvim", "nvimtools/none-ls-extras.nvim" },
			event = { "BufReadPost", "BufNewFile" },
			config = function()
				require("lsp.null-ls")
			end,
		},

		-- Autocompletion
		{
			"saghen/blink.cmp",
			dependencies = {
				"saghen/blink.lib",
				"rafamadriz/friendly-snippets",
				{
					"L3MON4D3/LuaSnip",
					version = "2.*",
					build = "make install_jsregexp",
					config = function()
						require("luasnip.loaders.from_vscode").lazy_load()
						require("luasnip.loaders.from_vscode").lazy_load({
							paths = { vim.fn.stdpath("config") .. "/snippets" },
						})
					end,
				},
			},
			event = "InsertEnter",
			build = function()
				require("blink.cmp").build():pwait()
			end,
			config = function()
				require("lsp.blink")
			end,
		},

		-- Languages Plugins

		--   Typescript
		{
			"pmizio/typescript-tools.nvim",
			dependencies = { "nvim-lua/plenary.nvim" },
			ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
		},

		--   Markdown
		{
			"iamcco/markdown-preview.nvim",
			cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
			build = "cd app && npm install",
			init = function()
				vim.g.mkdp_filetypes = { "markdown" }
			end,

			config = function()
				require("core.mkdp")
			end,
			ft = { "markdown" },
		},

		-- Go
		{
			"olexsmir/gopher.nvim",
			ft = "go",
			build = function()
				vim.cmd.GoInstallDeps()
			end,
			opts = {},
		},
	},
})
