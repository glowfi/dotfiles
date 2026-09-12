-- Settings
local status_ok, ts = pcall(require, "nvim-treesitter")
if not status_ok then
	return
end

-- Parsers
ts.install({
	"python",
	"go",
	"rust",
	"zig",
	"javascript",
	"typescript",
	"tsx",
	"html",
	"css",
	"c",
	"cpp",
	"json",
	"lua",
	"bash",
	"fish",
	"sql",
	"yaml",
	"toml",
	"markdown",
	"markdown_inline",
	"dockerfile",
	"csv",
	"gomod",
	"requirements",
	"jsonnet",
	"vim",
	"vimdoc",
	"query",
	"latex",
})

-- Highlight + indent per buffer
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("nvim/highlight_indent_treesitter", { clear = true }),
	callback = function(ev)
		if not pcall(vim.treesitter.start, ev.buf) then
			return
		end
		vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})
