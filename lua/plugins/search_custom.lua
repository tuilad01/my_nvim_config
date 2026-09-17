local COMMANDS = {
	searchText = {
		"rg",
		"-i", "--hidden",
		"--vimgrep",
		"-g", "!.git",
		"-g", "!node_modules",
		"-g", "!bin",
		"-g", "!obj",
	},
	searchFiles = {
		"rg",
		"--files", "--hidden",
		"--glob-case-insensitive",
		"-g", "!.git",
		"-g", "!node_modules",
		"-g", "!bin",
		"-g", "!obj",
	},
}


vim.api.nvim_create_user_command("F", function(opts)
	local query = opts.fargs[1]
	local directory = opts.fargs[2]
	local command = vim.deepcopy(COMMANDS.searchText)

	if directory ~= nil and directory ~= "" and directory ~= "--" then
		local directory_pattern = create_query_with_directory(directory)
		table.insert(command, 5, "-g")
		table.insert(command, 6, directory_pattern)
	end

	table.insert(command, query)

	add_custom_query(command, opts.fargs)
	execute({ command = command, query = query })
end, { nargs = "*", desc = "search text" })

vim.api.nvim_create_user_command("Ff", function(opts)
	local query = opts.fargs[1]
	local directory = opts.fargs[2]
	local command = vim.deepcopy(COMMANDS.searchFiles)

	local query_pattern = ""
	if directory ~= nil and directory ~= "" and directory ~= "--" then
		query_pattern = create_query_with_directory(directory, query)
	else
		query_pattern = create_query_with_file_name(query)
	end

	table.insert(command, 5, "-g")
	table.insert(command, 6, query_pattern)

	add_custom_query(command, opts.fargs)
	execute({ command = command, query = query, is_file_format = true })
end, {
	nargs = "*",
	desc = "search files"
})


function format_result(output, opts)
	local raw_lines = vim.split(output, "\n", { trimempty = true })
	if not opts.is_file_format then
		return raw_lines
	end

	local lines = {}
	for _, line in ipairs(raw_lines) do
		table.insert(lines, line .. ":1:1: [File entry]")
	end
	return lines
end

function set_quickfix_list(title, lines)
	vim.fn.setqflist({}, "r", {
		title = title,
		lines = lines,
	})

	vim.cmd("copen")
end

function set_hlsearch(query)
	vim.fn.setreg("/", query)
	vim.opt.hlsearch = true
end

function create_query_with_directory(directory, file_name)
	if file_name ~= nil and file_name ~= "" then
		return string.format("**/*%s*/**/*%s*", directory, file_name)
	end
	return string.format("**/*%s*/**", directory)
end

function create_query_with_file_name(file_name)
	return string.format("**/*%s*", file_name)
end

function add_custom_query(command, fargs)
	if #fargs > 2 then
		table.move(fargs, 3, #fargs, #command + 1, command)
	end
end

function execute(args)
	local command, query, is_file_format = args.command, args.query, args.is_file_format
	-- debugging
	print(vim.inspect(command))
	local start_time = os.clock()
	vim.system(command, { text = true }, function(obj)
		local output = obj.stdout or ""
		vim.schedule(function()
			local lines = format_result(output, { is_file_format = is_file_format })

			local elapsed = os.clock() - start_time
			set_quickfix_list(string.format("rg: %s - taken time: %.2f ms ", query, elapsed * 1000), lines)
			set_hlsearch(query)
		end)
	end)
end
