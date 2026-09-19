-- Set space as the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Splits

-- Vertical split
vim.keymap.set("n", "<Leader>v", "<cmd>vsplit<CR>", { silent = true, desc = "Vertical split" })

-- Horizontal split
vim.keymap.set("n", "<Leader>h", "<cmd>split<CR>", { silent = true, desc = "Horizontal split" })

-- Quit current window
vim.keymap.set("n", "<C-q>", "<cmd>quit<CR>", { silent = true, desc = "Quit window" })

-- Save current file
vim.keymap.set("n", "<S-s>", "<cmd>write<CR>", { silent = true, desc = "Save file" })

-- Search & replace

-- Replace: prompt with cursor placed inside the pattern
vim.keymap.set("n", "<Leader>r", ":%s///g<Left><Left>", { desc = "Replace in file" })

-- Replace visually selected text across the file (with confirm)
vim.keymap.set("v", "<Leader>r", '"hy:%s/<C-r>h//gc<Left><Left><Left>', { desc = "Replace selection" })

-- Clear search highlights
vim.keymap.set("n", "<C-Space>", '<cmd>let @/=""<CR>', { silent = true, desc = "Clear search highlight" })

-- Insert/cmdline: ctrl-backspace deletes previous word ─────

vim.keymap.set({ "i", "c" }, "<C-BS>", "<C-w>", { desc = "Delete previous word" })
vim.keymap.set({ "i", "c" }, "<C-h>", "<C-w>", { desc = "Delete previous word" })

-- Window navigation

vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true, desc = "Window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true, desc = "Window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true, desc = "Window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true, desc = "Window right" })

-- Window resizing

vim.keymap.set("n", "<M-Up>", "<cmd>resize +2<CR>", { silent = true, desc = "Grow height" })
vim.keymap.set("n", "<M-Down>", "<cmd>resize -2<CR>", { silent = true, desc = "Shrink height" })
vim.keymap.set("n", "<M-Left>", "<cmd>vertical resize -2<CR>", { silent = true, desc = "Shrink width" })
vim.keymap.set("n", "<M-Right>", "<cmd>vertical resize +2<CR>", { silent = true, desc = "Grow width" })

-- Move visual selection

vim.keymap.set("x", "K", ":move '<-2<CR>gv-gv", { silent = true, desc = "Move selection up" })
vim.keymap.set("x", "J", ":move '>+1<CR>gv-gv", { silent = true, desc = "Move selection down" })

-- Clipboard / selection

-- Copy whole file to system clipboard
vim.keymap.set("n", "<Leader>y", "<cmd>%y+<CR>", { silent = true, desc = "Yank file to clipboard" })

-- Select all
vim.keymap.set("n", "<C-a>", "ggVG", { silent = true, desc = "Select all" })

-- Increment / decrement numbers

vim.keymap.set("n", "<C-i>", "<C-a>", { desc = "Increment number" })
vim.keymap.set("n", "<C-d>", "<C-x>", { desc = "Decrement number" })

-- Insert German special characters

vim.keymap.set("i", "<C-a>", "ä")
vim.keymap.set("i", "<M-a>", "Ä")
vim.keymap.set("i", "<C-o>", "ö")
vim.keymap.set("i", "<M-o>", "Ö")
vim.keymap.set("i", "<C-u>", "ü")
vim.keymap.set("i", "<M-u>", "Ü")
vim.keymap.set("i", "<C-b>", "ß")

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Ctrl-/ to toggle comments (builtin gc)

vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("v", "<C-/>", "gc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "Toggle comment" })
