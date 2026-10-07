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

function set_hlsearch(query)
	vim.fn.setreg("/", query)
	vim.opt.hlsearch = true
end

local function search(opts)
	local input = opts.args
	if input == nil then
		return
	end

	search_query = input
	perform_search(search_query)

	set_hlsearch(search_query)
	vim.api.nvim_feedkeys("n", "n", false)
end

vim.api.nvim_create_user_command("BuildTreeFind", function(opts)
	search(opts)
end, { nargs = "*", desc = "Build tree" })

local function show_node_path()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local node = line_nodes[line]

	if not node then
		return
	end

	vim.notify(node.path, vim.log.levels.INFO)
end

local function copy_node_path()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local node = line_nodes[line]

	if not node then
		return
	end

	vim.fn.setreg("+", node.path)

	vim.notify("Copied: " .. node.path)
end

local function search_tree_include(nodes, dir_query, file_query, parents)
	parents = parents or {}

	for _, node in ipairs(nodes) do
		if node.is_dir then
			table.insert(parents, node)

			search_tree_include(
				node.children,
				dir_query,
				file_query,
				parents
			)

			table.remove(parents)
		else
			local file_match =
					node.name:lower():find(file_query, 1, true)

			local dir_match = false

			for _, parent in ipairs(parents) do
				if parent.name:lower():find(dir_query, 1, true) then
					dir_match = true
					break
				end
			end

			if file_match and dir_match then
				for _, parent in ipairs(parents) do
					parent.expand = true
				end
			end
		end
	end
end

local function perform_search_include(dir_query, file_query)
	collapse_all(tree)

	dir_query = dir_query:lower()
	file_query = file_query:lower()

	search_tree_include(
		tree,
		dir_query,
		file_query
	)

	render()

	-- Move cursor to the first visible matching file
	for line, node in pairs(line_nodes) do
		if not node.is_dir
				and node.name:lower():find(file_query, 1, true)
		then
			local has_dir_match = false
			local path = node.path:lower()

			if path:find(dir_query, 1, true) then
				has_dir_match = true
			end

			if has_dir_match then
				-- vim.api.nvim_win_set_cursor(0, { line, 0 })

				set_hlsearch(node.name)
				vim.api.nvim_feedkeys("n", "n", false)

				break
			end
		end
	end
end

vim.api.nvim_create_user_command("BuildTreeFindInclude", function(opts)
	local dir_query = opts.fargs[1]
	local file_query = opts.fargs[2]

	if not dir_query or not file_query then
		vim.notify(
			"Usage: BuildTreeFindInclude <directory> <filename>",
			vim.log.levels.ERROR
		)
		return
	end

	perform_search_include(dir_query, file_query)
end, {
	nargs = "*",
	desc = "Find file by directory and filename",
})

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

		vim.keymap.set("n", "K", show_node_path, {
			buffer = buf,
			silent = true,
		})

		vim.keymap.set("n", "<leader>cp", copy_node_path, {
			buffer = buf,
			silent = true,
		})

		vim.keymap.set("n", "<leader>f", function()
			vim.api.nvim_feedkeys(
				vim.api.nvim_replace_termcodes(":BuildTreeFind ", true, false, true),
				"n",
				false
			)
		end, {
			buffer = buf,
			silent = true,
		})
	end,
})

vim.keymap.set("n", "<C-p>", function()
	local filename = vim.fn.expand("%:t")

	vim.cmd("BuildTree")

	if filename ~= nil and filename ~= "" then
		vim.cmd(":BuildTreeFind " .. vim.fn.fnameescape(filename))
		return
	end

	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes(":BuildTreeFind " .. vim.fn.fnameescape(filename), true, false, true),
		"n",
		false
	)
end, {
	desc = "BuildTree Find",
})
