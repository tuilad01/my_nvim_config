local function git_status()
	local output = vim.fn.systemlist({
		"git",
		"status",
		"--short",
	})

	if vim.v.shell_error ~= 0 then
		vim.notify("Not a git repository", vim.log.levels.ERROR)
		return
	end

	local items = {}

	for _, line in ipairs(output) do
		if line ~= "" then
			local status = line:sub(1, 2)
			local file = line:sub(4)

			table.insert(items, {
				filename = file,
				lnum = 1,
				col = 1,
				text = status .. " - [GIT FILE CHANGE]",
			})
		end
	end

	vim.fn.setqflist({}, " ", {
		title = "Git Status --short",
		items = items,
	})

	vim.cmd("copen")
end

vim.api.nvim_create_user_command("GitStatus", git_status, {})


-- local function git_diff_file()
-- 	local file = vim.fn.expand("%:.")
--
-- 	-- Create a vertical split
-- 	vim.cmd("vnew")
--
-- 	local old_buf = vim.api.nvim_get_current_buf()
--
-- 	-- Load HEAD version into the new buffer
-- 	local output = vim.fn.systemlist({
-- 		"git",
-- 		"show",
-- 		"HEAD:" .. file,
-- 	})
--
-- 	if vim.v.shell_error ~= 0 then
-- 		vim.cmd("close")
-- 		vim.notify("Cannot compare this file with HEAD", vim.log.levels.WARN)
-- 		return
-- 	end
--
-- 	vim.api.nvim_buf_set_lines(old_buf, 0, -1, false, output)
--
-- 	vim.bo[old_buf].buftype = "nofile"
-- 	vim.bo[old_buf].bufhidden = "wipe"
-- 	vim.bo[old_buf].swapfile = false
-- 	vim.bo[old_buf].modifiable = false
-- 	vim.bo[old_buf].filetype = vim.bo.filetype
--
-- 	-- Put HEAD version on the left
-- 	vim.cmd("diffthis")
--
-- 	-- Move to working-tree buffer
-- 	vim.cmd("wincmd l")
-- 	vim.cmd("diffthis")
-- end

-- vim.api.nvim_create_autocmd("FileType",
-- 	{
-- 		pattern = "qf",
-- 		callback = function()
-- 			vim.keymap.set("n", "<CR>", function()
-- 				local qf = vim.fn.getqflist({ items = 0, idx = 0 })
--
-- 				local item = qf.items[qf.idx]
--
-- 				print(vim.inspect(item))
-- 				if not item or not item.filename then
-- 					return
-- 				end
--
-- 				-- Jump to the selected file
-- 				vim.cmd("cc")
--
-- 				-- Show Git diff
-- 				git_diff_file()
-- 			end, {
-- 				buffer = true,
-- 				desc = "Open file with Git diff",
-- 			})
-- 		end,
-- 	})
