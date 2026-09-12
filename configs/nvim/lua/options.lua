-- Indentation

-- Smart autoindenting on new lines
vim.o.smartindent = true

-- Copy indent from previous line
vim.o.copyindent = true

-- Set shift width to 4 spaces.
vim.o.shiftwidth = 4

-- Set tab width to 4 columns.
vim.o.tabstop = 4

-- Use space characters instead of tabs.
vim.o.expandtab = true

-- UI

-- Add numbers to each line on the left-hand side.
vim.o.number = true

-- Enable relative numbering
-- vim.o.relativenumber = true

-- Display long lines as just one line
vim.o.wrap = false

-- Do not let cursor scroll below or above N number of lines when scrolling.
vim.o.scrolloff = 10

-- More space for displaying messages
vim.o.cmdheight = 2

-- Makes popup menu smaller
vim.o.pumheight = 10

-- Don't show the mode on the last line (statusline shows it)
vim.o.showmode = false

-- Show matching words during a search.
vim.o.showmatch = true

-- Set terminal true colors
vim.o.termguicolors = true

-- Highlight current line
vim.o.cursorline = true

-- Gutter always visible, no layout shift
vim.o.signcolumn = "yes"

-- Search

-- Ignore capital letters during search.
vim.o.ignorecase = true

-- Override the ignorecase option if searching for capital letters.
vim.o.smartcase = true

-- Make substitution work in realtime
vim.o.inccommand = "split"

-- Files: no swap/backup, persistent undo

-- Disable backup files
vim.o.backup = false

-- Disable backup before overwriting
vim.o.writebackup = false

-- Disable swap files
vim.o.swapfile = false

-- Enable persistent undo
vim.o.undofile = true

-- Set undo directory
vim.o.undodir = vim.fn.stdpath("cache") .. "/undo"

-- Behavior

-- Horizontal splits will automatically be below
vim.o.splitbelow = true

-- Vertical splits will automatically be to the right
vim.o.splitright = true

-- Faster CursorHold (diagnostics, gitsigns)
vim.o.updatetime = 250

-- Snappier leader-key sequences
vim.o.timeoutlen = 300

-- Prompt instead of failing :q on unsaved changes
vim.o.confirm = true

-- Wrapped lines keep indent (if wrap ever on)
vim.o.breakindent = true

-- Copy paste between vim and everything else
-- Scheduled to defer the clipboard provider probe past startup
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- Don't pass messages to |ins-completion-menu|.
vim.opt.shortmess:append("c")

-- Treat dash separated words as a word text object
vim.opt.iskeyword:append("-")

-- Ignore compiled Python in command-line completion
vim.opt.wildignore = {
	"*.docx",
	"*.jpg",
	"*.png",
	"*.gif",
	"*.pdf",
	"*.pyc",
	"__pycache__",
	"*.exe",
	"*.flv",
	"*.img",
	"*.xlsx",
}

-- Whitespace rendering

-- Show invisible characters
-- vim.o.list = true
-- vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Title

-- Set terminal window title
vim.o.title = true

-- Title format
vim.o.titlestring = "%<%F%=%l/%L - nvim"

-- Restore terminal title on exit
vim.o.titleold = vim.env.TERMINAL or ""

-- Split bars

-- Make split bar character transparent
vim.opt.fillchars:append({ vert = " " })

-- Split bar highlight (WinSeparator replaced VertSplit)
vim.api.nvim_set_hl(0, "WinSeparator", { bg = "White", fg = "Black", ctermbg = 6, ctermfg = 0 })

-- Misc

-- Disables a sql error
vim.g.omni_sql_no_default_maps = 1

-- Filetype additions

-- Make conf,env,tiltfile detected as their proper filetypes
vim.filetype.add({
	extension = {
		conf = "conf",
		env = "dotenv",
		tiltfile = "tiltfile",
		Tiltfile = "tiltfile",
	},
	filename = {
		[".env"] = "dotenv",
		["tsconfig.json"] = "jsonc",
		[".yamlfmt"] = "yaml",
	},
	pattern = {
		["%.env%.[%w_.-]+"] = "dotenv",
	},
})

-- Dont show linenumbers in startup page
vim.api.nvim_create_autocmd("UIEnter", {
	group = vim.api.nvim_create_augroup("nvim/disable_linenumber_startup_page", { clear = true }),
	callback = function()
		-- only if we started with no file arguments and buffer is untouched
		if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" and not vim.bo.modified then
			vim.wo.number = false
			vim.wo.relativenumber = false
			vim.wo.cursorline = false
			vim.wo.signcolumn = "no"
			vim.api.nvim_create_autocmd("BufReadPost", {
				once = true,
				callback = function()
					vim.wo.number = true
					vim.wo.cursorline = true
					vim.wo.signcolumn = "yes"
				end,
			})
		end
	end,
})
