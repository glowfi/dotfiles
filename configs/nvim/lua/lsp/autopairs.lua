-- Settings
local status_ok, npairs = pcall(require, "nvim-autopairs")
if not status_ok then
	return
end

npairs.setup({
	check_ts = true,
	ts_config = {
		lua = { "string", "source" },
	},
	disable_filetype = { "TelescopePrompt" },
	fast_wrap = {
		map = "<M-e>",
	},
})
