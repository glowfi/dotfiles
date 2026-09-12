-- Settings
local status_ok, null_ls = pcall(require, "null-ls")
if not status_ok then
	return
end

local b = null_ls.builtins

-- prettierd: shared config location
vim.env.PRETTIERD_DEFAULT_CONFIG = vim.fn.stdpath("config") .. "/.prettierrc"

null_ls.setup({
	sources = {
		require("none-ls.diagnostics.ruff"),
		b.formatting.black,
		b.formatting.stylua,
		b.formatting.shfmt,
		b.formatting.fish_indent,
		b.formatting.prettierd,
		b.formatting.goimports,
		b.formatting.gofumpt,
	},
})

-- Format on save (only via null-ls)
vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("nvim/format-on-save", { clear = true }),
	callback = function(ev)
		vim.lsp.buf.format({
			bufnr = ev.buf,
			filter = function(client)
				return client.name == "null-ls"
			end,
		})
	end,
})
