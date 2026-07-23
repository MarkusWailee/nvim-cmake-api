local helper = {}

function helper.write_file(file_path, src)
	src = src or ""
	local dir = vim.fs.dirname(file_path)
	vim.fn.mkdir(dir, "p")
	local file = io.open(file_path, "w")
	if file then
		file:write(src);
		file:close()
		vim.notify(file_path, vim.log.levels.INFO, { title = "CMake: Created File" })
	else
		error("Failed to write file: " .. file_path, 0)
	end
end

function helper.read_dir(dir)
	if vim.fn.isdirectory(dir) == 0 then
		error("Directory does not exist: " .. dir, 0)
	end

	return vim.fn.readdir(dir)
end

function helper.read_file(path)
	local file = io.open(path, "r")

	if not file then
		error("Failed to read file: " .. path, 0)
	end
	local contents = file:read("*a")
	contents = contents or ""
	file:close()
	return contents
end

function helper.read_json(path)
	local str = helper.read_file(path)
	local json = vim.json.decode(str)
	if json == nil then
		error("Failed to read json: " .. path, 0)
	end
	return json
end

function helper.does_file_exist(file_name)
	return vim.uv.fs_stat(file_name) ~= nil
end

-- ==================== CMAKE API ====================

local query_dir = "build/.cmake/api/v1/query/"
local reply_dir = "build/.cmake/api/v1/reply/"
local cmake = {
}


--[[
returns the index json file
]]
function cmake.index_json()
	local function get_index_filename()
		local dirs = helper.read_dir(reply_dir)
		for _, file in ipairs(dirs) do
			if file:match("^index") then
				return file
			end
		end
		error("Failed to find Index path")
	end
	local index_path = reply_dir .. get_index_filename()
	local index_json = helper.read_json(index_path)
	return index_json
end

--[[
returns the codemodelv2 json file.
Used to give information of the entire project
]]
function cmake.codemodelv2_json()
	local index_json = cmake.index_json()
	local codemodel_filename = index_json.reply["codemodel-v2"].jsonFile
	if codemodel_filename == nil then
		error("Could not find file: codemodelv2*.json", 0)
	end
	local codemodel_json = helper.read_json(reply_dir .. codemodel_filename)
	return codemodel_json
end

--[[
returns a table of each target json file
]]
function cmake.targets_json()
	local codemodel_json = cmake.codemodelv2_json()
	if codemodel_json.configurations == nil then
		error("codemodelv2_json.configurations is nil")
	end

	local result = {}
	for _, config in ipairs(codemodel_json.configurations) do
		for _, target in ipairs(config.targets) do
			local target_json = helper.read_json(reply_dir .. target.jsonFile)
			table.insert(result, target_json)
		end
	end
	return result
end

--[[
Returns the cache json file containing all the -D variables
]]
function cmake.cachev2_json()
	local index_json = cmake.index_json()
	local cache_filename = index_json.reply["cache-v2"].jsonFile
	if cache_filename == nil then
		error("Could not find file: cache-v2*.json", 0)
	end
	return helper.read_json(reply_dir .. cache_filename)
end

--[[
returns all -D flags inside cache-v2-*.json
]]
local function get_variables(filter)
	local cache = cmake.cachev2_json()
	if cache.entries == nil then
		error("Cache Entries is nil value")
	end

	local result = {}
	for _, entry in ipairs(cache.entries) do
		if filter(entry) then
			table.insert(result, entry)
		end
	end
	return result
end

function cmake.user_variables()
	local function is_user_editable(entry)
		-- Hide internal cache entries
		if entry.type == "INTERNAL" or entry.type == "STATIC" then
			return false
		end
		-- Hide entries without descriptions
		if entry.help == "" then
			return false
		end

		if entry.name:match("^CMAKE_") then
			return false
		end

		if entry.type == "FILEPATH" then
			return false
		end
		return true
	end
	local v = get_variables(is_user_editable)
	return v
end

function cmake.cmake_variables()
	local function is_cmake_var(entry)
		-- Hide internal cache entries
		if entry.type == "INTERNAL" or entry.type == "STATIC" then
			return false
		end
		-- Hide entries without descriptions
		if entry.help == "" then
			return false
		end

		if entry.type == "FILEPATH" then
			return false
		end

		if not entry.name:match("^CMAKE_") then
			return false
		end

		return true
	end
	local v = get_variables(is_cmake_var)
	return v
end

function cmake.generate_api_file()
	local codemodel_path = query_dir .. "codemodel-v2"
	local cache_path = query_dir .. "cache-v2"

	if not vim.uv.fs_stat(codemodel_path) then -- ignore when file exists
		helper.write_file(codemodel_path)
	end

	if not vim.uv.fs_stat(cache_path) then -- ignore when file exists
		helper.write_file(cache_path)
	end
end

--[[
returns a table of all targets and executable paths
{
	{ name = "example1", type = "EXECUTABLE", path = "Debug/example1" }
}
]]
function cmake.get_targets()
	local targets_json = cmake.targets_json()
	local result = {}
	for _, t in ipairs(targets_json) do
		table.insert(result, {name = t.name, type = t.type, path = t.artifacts[1].path})
	end
	return result
end

return cmake
