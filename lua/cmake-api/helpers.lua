local m = {}
function m.write_file(file_path, src)
	local file = io.open(file_path, "w")
	local dir vim.fs.dirname(file_path)
	vim.fn.mkdir(dir, "p")
	if file then
		file:write(src);
		file:close()
		return true
	end
	return false
end

function m.read_dir(dir)
	return vim.fn.readdir(dir);
end

function m.read_file(path)
	local file = io.open(path, "r")

	if not file then
		return nil
	end
	local contents = file:read("*a")
	file:close()
	return contents
end
function m.read_json(path)
	local str = m.read_file(path)
	if str then
		local json = vim.json.decode(str)
		if json then
			return json
		end
	end
	return nil
end


