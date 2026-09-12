-- Settings
local status_ok, gruvbox = pcall(require, "gruvbox")
if not status_ok then
	return
end

gruvbox.setup({
	transparent_mode = true,
})

-- Highlight overrides: applied now and re-applied on any colorscheme reload
local function hl_overrides()
	-- Amber current line number, no bar
	vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#fabd2f", bg = "NONE" })

	-- LSP reference highlights (document_highlight under cursor)
	vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#404040" })
	vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#404040" })
	vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#4a4440", bold = true })
end

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("nvim/hl-overrides", { clear = true }),
	callback = hl_overrides,
})

vim.o.background = "dark"
vim.cmd.colorscheme("gruvbox")

-- Cursorline: highlight only the line number
vim.o.cursorlineopt = "number"
