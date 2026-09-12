-- Settings
local status_ok, ibl = pcall(require, "ibl")
if not status_ok then
	return
end

-- Highlight color
local highlight = {
	"RainbowRed",
	"RainbowYellow",
	"RainbowBlue",
	"RainbowOrange",
	"RainbowGreen",
	"RainbowViolet",
	"RainbowCyan",
}

local hooks = require("ibl.hooks")
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#D70000" })
	vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#fabd2f" })
	vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#7788AA" })
	vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#ffAA88" })
	vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#789978" })
	vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#D7007D" })
	vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#708090" })
end)

-- Settings
ibl.setup({
	indent = { highlight = highlight, char = "┊" },
	scope = { enabled = false },
})
