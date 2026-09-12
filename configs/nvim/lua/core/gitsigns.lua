-- Settings
local status_ok, gitsigns = pcall(require, "gitsigns")
if not status_ok then
	return
end

gitsigns.setup({
	signs = {
		add = { text = "┃" },
		change = { text = "┃" },
		delete = { text = "┃" },
		topdelete = { text = "┃" },
		changedelete = { text = "┃" },
	},
	on_attach = function(bufnr)
		vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { buffer = bufnr, desc = "Preview git hunk" })

		-- don't override the built-in diff-mode ]c/[c
		vim.keymap.set({ "n", "v" }, "]c", function()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gitsigns.nav_hunk("next")
			end
		end, { buffer = bufnr, desc = "Jump to next hunk" })

		vim.keymap.set({ "n", "v" }, "[c", function()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gitsigns.nav_hunk("prev")
			end
		end, { buffer = bufnr, desc = "Jump to previous hunk" })
	end,
	sign_priority = 6,
	update_debounce = 200,
})
