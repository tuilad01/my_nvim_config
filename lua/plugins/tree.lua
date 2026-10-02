local excluded = {
	["."] = true,
	[".."] = true,
	[".git"] = true,
	["node_modules"] = true,
	["bin"] = true,
	["obj"] = true,
	[".angular"] = true,
}

local function build_tree(path)
	local result = {}

	for _, name in ipairs(vim.fn.readdir(path)) do
		-- Skip "." and ".."

		if not excluded[name] then
			local full_path = path .. "/" .. name
			local is_dir = vim.fn.isdirectory(full_path) == 1

			local node = {
				name = name,
				path = full_path,
				expand = true,
			}

			if is_dir then
				node.children = build_tree(full_path)
			end

			table.insert(result, node)
		end
	end

	-- Directories first, then files
	table.sort(result, function(a, b)
		if a.children and not b.children then
			return true
		elseif not a.children and b.children then
			return false
		end

		return a.name:lower() < b.name:lower()
	end)

	return result
end

local function tree_to_lines(tree, level, lines)
	level = level or 0
	lines = lines or {}

	for _, node in ipairs(tree) do
		local indent = string.rep("  ", level)

		local icon = node.children and " " or "󰈙 "

		table.insert(lines, indent .. icon .. node.name)

		if node.expand and node.children then
			tree_to_lines(node.children, level + 1, lines)
		end
	end

	return lines
end

local function render_tree(tree, bufnr)
	local lines = tree_to_lines(tree)

	vim.api.nvim_buf_set_lines(
		bufnr,
		0,
		-1,
		false,
		lines
	)
end

vim.api.nvim_create_user_command("BuildTree", function()
	local cwd = vim.fn.getcwd()
	local tree = build_tree(cwd)
	-- local lines = tree_to_lines(tree)
	-- print(vim.inspect(result))
	-- for _, line in ipairs(lines) do
	-- 	print(line)
	-- end
	local bufnr = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
	vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(bufnr, "swapfile", false)

	vim.api.nvim_set_current_buf(bufnr)
	render_tree(tree, bufnr)
end, { desc = "Build tree" })
