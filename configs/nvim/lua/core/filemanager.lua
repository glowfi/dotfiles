-- Settings
local status_ok, filemanager = pcall(require, "nnn")
if not status_ok then
	return
end

filemanager.setup({
	command = "nnn -d -e",
	session = "local",
	set_default_mappings = 0,
	replace_netrw = 1,
	layout = {
		window = { width = 0.6, height = 0.6, highlight = "Debug" },
	},
})

-- Keymappings
vim.keymap.set("n", "<leader>nn", "<cmd>NnnPicker %:p:h<CR>", { silent = true, desc = "nnn picker (file's dir)" })
