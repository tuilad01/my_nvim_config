-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.hlsearch = true
vim.opt.clipboard = "unnamedplus"
vim.opt.grepprg = "rg --vimgrep --smart-case"

-- Keymap

vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
	vim.lsp.buf.format()
end, { desc = "Format current buffer" })

vim.keymap.set("n", "<leader>co", "<cmd>copen<CR>", {
	desc = "Open quickfix",
})

vim.keymap.set("n", "<leader>cc", "<cmd>cclose<CR>", {
	desc = "Close quickfix",
})

vim.keymap.set("n", "∆", "<cmd>cnext<CR>", {
	desc = "Next quickfix",
})

vim.keymap.set("n", "˚", "<cmd>cprev<CR>", {
	desc = "Previous quickfix",
})
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(event)
		local opts = { buffer = event.buf, silent = true }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
		vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
		vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { desc = "Go to implementation" })

		vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "Signature help" })

		vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
	end,
})

-- Neovim pack management
vim.pack.add({ "https://github.com/catppuccin/nvim" })
vim.cmd.colorscheme "catppuccin-nvim"

-- fix transparent on mac
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "FoldColumn", { bg = "none" })

vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/saghen/blink.lib",
	"https://github.com/saghen/blink.cmp",
	"https://github.com/tpope/vim-fugitive",
})
local cmp = require('blink.cmp')
cmp.build():pwait()

cmp.setup({
	keymap = {
		preset = "default",
	},

	completion = {
		documentation = {
			auto_show = true,
		},
	},

	sources = {
		default = { "lsp", "path", "buffer" },
	},
})

vim.lsp.config("lua_ls", {
	capabilities = cmp.get_lsp_capabilities()
})
vim.lsp.enable("lua_ls")


-- Custom command
require("plugins.search_custom")
