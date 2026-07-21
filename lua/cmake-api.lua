local cmake = require("cmake-api.cmake-api")
local m = {
	target = nil,
	build_type = "Debug"
}

function m.select_target()
	local t = cmake.get_targets()
	vim.ui.select(t, { format_item = function(item) return item.name end }, function(c)
		if c then
			m.target = c
		end
	end)
end

return m

