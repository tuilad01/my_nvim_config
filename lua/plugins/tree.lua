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
		if not excluded[name] then
			local full_path = path .. "/" .. name
			local is_dir = vim.fn.isdirectory(full_path) == 1

			local node = {
				name = name,
				path = full_path,
				expand = false,
				is_dir = is_dir,
			}

			if is_dir then
				node.children = build_tree(full_path)
			end

			table.insert(result, node)
		end
	end

	table.sort(result, function(a, b)
		if a.is_dir ~= b.is_dir then
			return a.is_dir
		end

		return a.name:lower() < b.name:lower()
	end)

	return result
end

local tree = build_tree(vim.fn.getcwd())
local line_nodes = {}
local bufnr = 0



local function tree_to_lines(tree, level, lines, line_nodes)
	level = level or 0
	lines = lines or {}
	line_nodes = line_nodes or {}

	for _, node in ipairs(tree) do
		local indent = string.rep("  ", level)

		local icon

		if node.is_dir then
			icon = node.expand and " " or " "
		else
			icon = "  "
		end

		table.insert(lines, indent .. icon .. node.name)

		local line = #lines
		line_nodes[line] = node

		if node.is_dir and node.expand then
			tree_to_lines(
				node.children,
				level + 1,
				lines,
				line_nodes
			)
		end
	end

	return lines, line_nodes
end

local function render()
	local lines

	lines, line_nodes = tree_to_lines(tree)

	vim.api.nvim_buf_set_lines(
		bufnr,
		0,
		-1,
		false,
		lines
	)
end


local function enter()
	-- print("Enter function start")
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local node = line_nodes[line]

	if not node then
		return
	end

	-- print("Enter node: ", vim.inspect(node))
	if node.is_dir then
		node.expand = not node.expand

		render()

		vim.api.nvim_win_set_cursor(0, { line, 0 })
	else
		vim.cmd("rightbelow vsplit " .. vim.fn.fnameescape(node.path))
	end
end


vim.api.nvim_create_user_command("BuildTree", function()
	local cwd = vim.fn.getcwd()
	tree = build_tree(cwd)
	bufnr = vim.api.nvim_create_buf(false, true)


	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].filetype = "mytree"

	vim.api.nvim_set_current_buf(bufnr)
	-- vim.keymap.set("n", "<CR>", enter, {
	-- 	buffer = bufnr,
	-- 	silent = true,
	-- })
	render()
end, { desc = "Build tree" })

local function collapse_all(nodes)
	for _, node in ipairs(nodes) do
		if node.is_dir then
			node.expand = false
			collapse_all(node.children)
		end
	end
end

local function search_tree(nodes, query, parents)
	parents = parents or {}

	for _, node in ipairs(nodes) do
		local matched = node.name:lower():find(query, 1, true)

		if matched then
			-- Expand all parents of this match
			for _, parent in ipairs(parents) do
				parent.expand = true
			end

			-- If the match itself is a directory,
			-- expand it too so its contents are visible.
			if node.is_dir then
				node.expand = true
			end
		end

		if node.is_dir then
			table.insert(parents, node)

			search_tree(node.children, query, parents)

			table.remove(parents)
		end
	end
end

local function perform_search(query)
	collapse_all(tree)

	if query ~= "" then
		search_tree(tree, query)
	end

	render()
end

local function search(opts)
	-- vim.ui.input({
	-- 	prompt = "Find: ",
	-- 	default = search_query,
	-- }, function(input)
	-- 	if input == nil then
	-- 		return
	-- 	end
	--
	-- 	search_query = input
	-- 	perform_search(search_query)
	-- end)
	local input = opts.args
	if input == nil then
		return
	end

	search_query = input
	perform_search(search_query)
end

vim.api.nvim_create_user_command("BuildTreeFind", search, { nargs = "*", desc = "Build tree" })


vim.api.nvim_create_autocmd("FileType", {
	pattern = "mytree",
	callback = function(args)
		local buf = args.buf

		vim.keymap.set("n", "<CR>", enter, {
			buffer = buf,
			silent = true,
		})

		vim.keymap.set("n", "q", "<cmd>bd<CR>", {
			buffer = buf,
			silent = true,
		})

		vim.keymap.set("n", "r", render, {
			buffer = buf,
			silent = true,
		})

		vim.keymap.set("n", "/", search, {
			buffer = bufnr,
			silent = true,
		})
	end,
})
