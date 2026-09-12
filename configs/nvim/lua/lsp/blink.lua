-- Settings
local status_ok, blink = pcall(require, "blink.cmp")
if not status_ok then
	return
end

blink.setup({
	keymap = {
		preset = "none",
		["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
		["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
		["<CR>"] = { "accept", "fallback" },
		["<C-Space>"] = { "show", "fallback" },
		["<C-e>"] = { "cancel", "fallback" },
		["<C-d>"] = { "scroll_documentation_up", "fallback" },
		["<C-f>"] = { "scroll_documentation_down", "fallback" },
	},

	signature = {
		enabled = true,
		trigger = {
			show_on_insert = true,
			show_on_trigger_character = true,
		},
	},

	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},

	cmdline = { enabled = false },

	completion = {
		list = { selection = { preselect = false, auto_insert = false } },
		menu = {
			border = "rounded",
			draw = {
				columns = {
					{ "label", "label_description", gap = 1 },
					{ "kind_icon", "kind", gap = 1 },
				},
			},
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 200,
			window = { border = "rounded", max_width = 120, max_height = 20 },
		},
	},

	snippets = { preset = "luasnip" },

	appearance = {
		nerd_font_variant = "mono",
		kind_icons = {
			Text = "",
			Method = "󰆧",
			Function = "󰊕",
			Constructor = "",
			Field = "",
			Variable = "[]",
			Class = "󰌗",
			Interface = "󰔡",
			Module = "󰅩",
			Property = "󰆅",
			Unit = "",
			Value = "󰎠",
			Enum = "󰕘",
			Keyword = "󰌋",
			Snippet = "",
			Color = " 󰏘",
			File = "󰈔",
			Reference = "󰈝",
			Folder = " 󰉋",
			EnumMember = "",
			Constant = "󰇽",
			Struct = "",
			Event = "",
			Operator = "󰃬",
			TypeParameter = "󰊄",
		},
	},
})
