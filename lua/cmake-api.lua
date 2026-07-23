local cmake = require("cmake-api.cmake-api")
local m = {
	target = nil,
	---@type string
	build_type = "Debug"
}

function m.select_target(success)
	local t = cmake.get_targets()
	vim.ui.select(t, { format_item = function(item) return item.name end }, function(c)
		if c then
			m.target = c
			success()
		end
	end)
end

function m.select_build_type(success)
	vim.ui.select({"Debug", "Release"}, {}, function(choice)
		if choice then
			m.build_type = choice
		end
	end)
end

function m.init()
	cmake.generate_api_file()
end

return m

