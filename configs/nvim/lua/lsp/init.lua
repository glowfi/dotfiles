-- Settings
-- Diagnostics
vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.HINT] = "",
			[vim.diagnostic.severity.INFO] = " ",
		},
	},
	virtual_text = { prefix = "", spacing = 3 },
	update_in_insert = false,
	severity_sort = true,
	underline = false,
})

-- Rounded borders for ALL floating windows (hover, signature, diagnostics)
vim.o.winborder = "rounded"

-- Keymaps + per-buffer features, on attach
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("nvim/lsp-attach", { clear = true }),
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client then
			return
		end

		local function nmap(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = "LSP: " .. desc })
		end

		nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
		nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
		nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
		nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
		nmap("<leader>f", require("telescope.builtin").lsp_references, "References")
		nmap("<leader>i", require("telescope.builtin").lsp_implementations, "Implementations")
		nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
		nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

		-- TypeScript (tsc): one-keypress source actions
		if client.name == "tsc" then
			nmap("<leader>to", function()
				vim.lsp.buf.code_action({
					context = { only = { "source.organizeImports" }, diagnostics = {} },
					apply = true,
				})
			end, "Organize imports")
			nmap("<leader>tf", function()
				vim.lsp.buf.code_action({
					context = { only = { "source.fixAll" }, diagnostics = {} },
					apply = true,
				})
			end, "Fix all")
		end

		-- Highlight other occurrences of the symbol under cursor when resting
		if client:supports_method("textDocument/documentHighlight") then
			local grp = vim.api.nvim_create_augroup("nvim/lsp-highlight-" .. ev.buf, { clear = true })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				group = grp,
				buffer = ev.buf,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				group = grp,
				buffer = ev.buf,
				callback = vim.lsp.buf.clear_references,
			})
			vim.api.nvim_create_autocmd("LspDetach", {
				group = grp,
				buffer = ev.buf,
				callback = function()
					vim.lsp.buf.clear_references()
					vim.api.nvim_del_augroup_by_id(grp)
				end,
			})
		end
	end,
})

-- Server configs

-- blink.cmp capabilities for every server
local blink_ok, blink = pcall(require, "blink.cmp")
if blink_ok then
	vim.lsp.config("*", {
		capabilities = blink.get_lsp_capabilities(),
	})
end

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
		},
	},
})

-- Custom server not in lspconfig: define directly
vim.lsp.config("ls_emmet", {
	cmd = { "ls_emmet", "--stdio" },
	filetypes = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "htmldjango" },
	root_markers = { ".git" },
})

vim.lsp.enable({
	"pyright",
	"rust_analyzer",
	"gopls",
	"zls",
	"clangd",
	"lua_ls",
	"html",
	"cssls",
	"tailwindcss",
	"jsonls",
	-- "graphql",
	"bashls",
	"ls_emmet",
	"tsc",
})

-- Zig

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("nvim/zig-fmt", { clear = true }),
	pattern = { "*.zig", "*.zon" },
	callback = function(ev)
		vim.lsp.buf.format({
			bufnr = ev.buf,
			filter = function(c)
				return c.name == "zls"
			end,
		})
	end,
})
