vim.api.nvim_create_user_command("Maps", function()
	-- Open a new tab
	vim.cmd("tabnew")

	-- Get all mappings
	local output = vim.fn.execute("silent map")

	-- Put the output into the new buffer
	local lines = vim.split(output, "\n", { plain = true })
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

	-- Make it read-only
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.bo.modifiable = false

	-- Give the buffer a useful name
	vim.cmd("file [Maps]")
end, {})

vim.api.nvim_create_user_command("SortMaps", function()
	vim.cmd("tabnew")

		local maps = vim.api.nvim_get_keymap("")

	table.sort(maps, function(a, b)
		if a.lhs == b.lhs then
			return a.mode < b.mode
		end
		return a.lhs < b.lhs
	end)

	local lines = {}

	for _, m in ipairs(maps) do
		local desc = m.desc or ""
		table.insert(lines, string.format(
			"%-3s %-15s %s",
			m.mode,
			m.lhs,
			desc ~= "" and desc or m.rhs
		))
	end

	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.bo.modifiable = false
	vim.bo.filetype = "vim"
end, {})
