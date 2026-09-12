-- Keymappings
vim.keymap.set("n", "<Tab>", "<cmd>BufferNext<CR>", { silent = true, desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>BufferPrevious<CR>", { silent = true, desc = "Previous buffer" })
vim.keymap.set("n", "<S-x>", "<cmd>BufferClose<CR>", { silent = true, desc = "Close buffer" })

-- Transparency
vim.api.nvim_set_hl(0, "BufferTabpageFill", { bg = "NONE" })
