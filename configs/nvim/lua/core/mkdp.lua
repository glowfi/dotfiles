-- Settings
vim.g.mkdp_refresh_slow = 1
vim.g.mkdp_browser = "/usr/bin/brave"
vim.g.mkdp_markdown_css = vim.fn.stdpath("config") .. "/custom.css"
vim.g.mkdp_port = "3030"
vim.g.markdown_fenced_languages = {
	"bash=sh",
	"python",
	"javascript",
	"js=javascript",
	"json=javascript",
	"typescript",
	"ts=typescript",
	"html",
	"css",
}
