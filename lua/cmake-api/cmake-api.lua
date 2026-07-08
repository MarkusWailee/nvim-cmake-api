local h = require("cmake-api.helpers")
local cmake_api_file =  "build/.cmake/api/v1/query/codemodel-v2"
local reply_dir = "build/.cmake/api/v1/reply/"
local cmake = {
}

local function get_index_file_path()
	local dirs = h.read_dir(reply_dir)
	for _, file in ipairs(dirs) do
		if file:match("^index") then
			return reply_dir .. file
		end
	end
	return nil
end

local function get_targets_from_codemodelv2_json()
	local index_path = get_index_file_path()
	if index_path == nil then
		vim.notify("Failed to find index json file", vim.log.levels.ERROR, { title = "CMake" })
		return nil
	end
	local index_json = h.read_json(index_path)
	if index_json == nil then
		vim.notify("Failed to load index json", vim.log.levels.ERROR, { title = "CMake" })
		return nil
	end
	local codemodel_filename = index_json.reply["codemodel-v2"].jsonFile
	if codemodel_filename == nil then
		vim.notify("Failed to find codemodel-v2", vim.log.levels.ERROR, { title = "CMake" })
		return nil
	end
	local codemodel_json = h.read_json(reply_dir .. codemodel_filename)
	if codemodel_json == nil then
		vim.notify("Failed to load codemodel-v2 json", vim.log.levels.ERROR, { title = "CMake" })
		return nil
	end

	local result = {}
	for _, config in ipairs(codemodel_json.configurations) do
		for _, target in ipairs(config.targets) do
			local json = h.read_json(reply_dir .. target.jsonFile)
			if json == nil then
				vim.notify("Failed to open target jsonFile", vim.log.levels.ERROR, { title = "CMake" })
				return nil
			end
			table.insert(result, json)
		end
	end
	return result
end


-- a function to get the raw json output of each cmake target.
-- **returns** a list of tables generated from json files of the pattern ./build/.cmake/api/v1/reply/targets-*.json
function cmake.get_targets_from_codemodelv2_json()
	return get_targets_from_codemodelv2_json()
end

function cmake.get_target_name_and_executable_path()
	local t = get_targets_from_codemodelv2_json()
	if t == nil then
		vim.notify("Failed to load cmake api json files", vim.log.levels.ERROR, { title = "CMake" })
		return nil
	end
	local result = {}
	for _, target in ipairs(t) do
		if target.type == "EXECUTABLE" then
			local temp = { name = target.name, path = "build/"..target.artifacts[1].path }
			table.insert(result, temp)
		end
	end
	return result
end

return cmake
