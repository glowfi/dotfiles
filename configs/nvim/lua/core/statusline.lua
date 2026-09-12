-- Settings
local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
	return
end

-- Conditions
local conditions = {
	hide_in_width = function()
		return vim.fn.winwidth(0) > 80
	end,
}

-- Cached external versions (io.popen once per session)
local cache = {}

local function cached_cmd(key, cmd)
	if cache[key] == nil then
		local handle = io.popen(cmd .. " 2>/dev/null")
		if handle then
			local out = handle:read("*a") or ""
			handle:close()
			cache[key] = vim.trim(out)
		else
			cache[key] = ""
		end
	end
	return cache[key]
end

-- Left components

-- Python venv/conda env
local function python_env()
	if vim.bo.filetype ~= "python" then
		return ""
	end
	local venv = vim.env.CONDA_DEFAULT_ENV or vim.env.VIRTUAL_ENV
	if not venv then
		return ""
	end
	return "env -> " .. vim.fs.basename(venv)
end

local function python_version()
	if vim.bo.filetype ~= "python" then
		return ""
	end
	return "󰌠 " .. cached_cmd("python", "python --version")
end

local function node_version()
	local fts = { javascript = true, typescript = true, javascriptreact = true, typescriptreact = true }
	if not fts[vim.bo.filetype] then
		return ""
	end
	return "󰎙 " .. cached_cmd("node", "node --version")
end

-- Right components

-- Treesitter active in this buffer
local function treesitter_status()
	if vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] then
		return " Treesitter"
	end
	return ""
end

-- Real LSP servers attached to this buffer (excluding the null-ls shim)
local function lsp_servers()
	local names = {}
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
		if client.name ~= "null-ls" then
			table.insert(names, client.name)
		end
	end
	if #names == 0 then
		return ""
	end
	return "LS:" .. table.concat(names, " ")
end

-- none-ls sources registered for this buffer's filetype, by role
local function null_ls_sources(method)
	local ok, sources = pcall(require, "null-ls.sources")
	if not ok then
		return {}
	end
	local names = {}
	for _, source in ipairs(sources.get_available(vim.bo.filetype, "NULL_LS_" .. method)) do
		if not vim.tbl_contains(names, source.name) then
			table.insert(names, source.name)
		end
	end
	return names
end

local function formatters()
	local names = null_ls_sources("FORMATTING")
	if #names == 0 then
		return ""
	end
	return "F:" .. table.concat(names, ",")
end

local function linters()
	local names = null_ls_sources("DIAGNOSTICS")
	if #names == 0 then
		return ""
	end
	return "L:" .. table.concat(names, ",")
end

-- Setup
lualine.setup({
	options = {
		icons_enabled = true,
		theme = "gruvbox-material",
		section_separators = "",
		component_separators = "",
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = {},
		lualine_c = {
			{ "branch", icon = "", color = { bg = "#e6e6e6", fg = "#000000", gui = "bold" } },
			{
				"diff",
				symbols = { added = " ", modified = " ", removed = " " },
				cond = conditions.hide_in_width,
			},
			{ python_env, color = { fg = "#ffffff", gui = "bold" } },
			{ python_version, color = { fg = "#ffffff", gui = "bold" } },
			{ node_version },
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				symbols = { error = " ", warn = " ", info = " " },
			},
		},
		lualine_x = {
			{ treesitter_status },
			{ lsp_servers, cond = conditions.hide_in_width },
			{ formatters, cond = conditions.hide_in_width },
			{ linters, cond = conditions.hide_in_width },
			{ "filetype" },
		},
		lualine_y = {},
		lualine_z = {},
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	},
})
