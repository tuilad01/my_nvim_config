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
--
-- vim.api.nvim_create_autocmd("WinEnter", {
-- 	callback = function()
-- 		vim.wo.winhighlight = "Normal:ActiveWindow,NormalNC:InactiveWindow"
-- 	end,
-- })
--
-- vim.api.nvim_create_autocmd("WinLeave", {
-- 	callback = function()
-- 		vim.wo.winhighlight = "Normal:InactiveWindow,NormalNC:InactiveWindow"
-- 	end,
-- })
--
-- Keymap

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() vim.lsp.buf.format() end, { desc = "Format current buffer" })
-- for quickfix list
vim.keymap.set("n", "<leader>co", "<cmd>copen<CR>", { desc = "Open quickfix", })
vim.keymap.set("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "Close quickfix", })
vim.keymap.set("n", "∆", "<cmd>cnext<CR>", { desc = "Next quickfix", })
vim.keymap.set("n", "˚", "<cmd>cprev<CR>", { desc = "Previous quickfix", })

-- for tabs
-- Next / previous tab
vim.keymap.set("n", "<leader>tn", "<cmd>tabnext<CR>")
vim.keymap.set("n", "<leader>tp", "<cmd>tabprevious<CR>")
-- New tab
vim.keymap.set("n", "<leader>tt", "<cmd>tabnew<CR>")
vim.keymap.set("n", "<leader>tc", "<cmd>tabclose<CR>")
-- Go to specific tab
vim.keymap.set("n", "<leader>t1", "1gt")
vim.keymap.set("n", "<leader>t2", "2gt")
vim.keymap.set("n", "<leader>t3", "3gt")

-- panel
vim.keymap.set("n", "<leader>th", "<cmd>belowright split<CR>")
vim.keymap.set("n", "<leader>tv", "<cmd>belowright vsplit<CR>")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
-- Resize windows using Control + Shift + Arrow keys
vim.keymap.set('n', '<C-Up>', ':resize +2<CR>', { desc = 'Resize split up' })
vim.keymap.set('n', '<C-Down>',':resize -2<CR>', { desc = 'Resize split down' })
vim.keymap.set('n', '<C-Left>',':vertical resize -2<CR>', { desc = 'Resize split left' })
vim.keymap.set('n', '<C-Right>', ':vertical resize +2<CR>', { desc = 'Resize split right' })


-- Close terminal
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(event)
		local opts = { buffer = event.buf, silent = true }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
		vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
		vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { desc = "Go to implementation" })

		vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
		vim.keymap.set("n", "gh", vim.lsp.buf.signature_help, { desc = "Signature help" })

		vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
	end,
})
-- copy current file path
vim.keymap.set("n", "<leader>cp", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end)


-- Neovim pack management
vim.pack.add({
	"https://github.com/catppuccin/nvim",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/saghen/blink.lib",
	"https://github.com/saghen/blink.cmp",
	"https://github.com/tpope/vim-fugitive",
	-- "https://github.com/sphamba/smear-cursor.nvim",
	-- "https://github.com/akinsho/bufferline.nvim",
	"https://github.com/nvim-lualine/lualine.nvim",
})

require("catppuccin").setup({
	transparent_background = false,
	dim_inactive = {
		enabled = true,
		shade = "dark",
		percentage = 0.15,
	},
})
vim.cmd.colorscheme "catppuccin-nvim"

require('lualine').setup()

-- require("bufferline").setup({
-- 	options = {
-- 		separator_style = "slant",
-- 		show_buffer_close_icons = false,
-- 		show_close_icon = false,
-- 		always_show_bufferline = false,
-- 	},
-- })

-- require("smear_cursor").setup({
-- 	stiffness = 0.8,
-- 	trailing_stiffness = 0.5,
-- 	distance_stop_animating = 0.5,
-- })

local cmp = require('blink.cmp')
cmp.build():pwait()

cmp.setup({
	keymap = { preset = "default", },
	completion = {
		documentation = {
			auto_show = true,
		},
		menu = {
			border = "rounded",
		},
	},
	cmdline = {
    keymap = {
      preset = "cmdline",
    },
    completion = {
      menu = {
        auto_show = true,
      },
    },
  },
	signature = {
		enabled = true,
		window = {
			show_documentation = true,
		},
	},
	sources = { default = { "lsp", "path", "buffer" }, },
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
	capabilities = cmp.get_lsp_capabilities(),
})
vim.lsp.enable({ "lua_ls", "rust_analyzer" })
-- fix transparent on mac
-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
-- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
-- vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
-- vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
-- vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
-- vim.api.nvim_set_hl(0, "FoldColumn", { bg = "none" })

-- Custom command
require("plugins.search_custom")
require("plugins.resize")
