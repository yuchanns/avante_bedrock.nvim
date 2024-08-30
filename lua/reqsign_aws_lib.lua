local M = {}

local library_path = function()
	local ext = vim.loop.os_uname().sysname == "Linux" and "so" or "dylib"
	local dirname = string.sub(debug.getinfo(1).source, 2, #"/reqsign_aws_lib.lua" * -1)
	return dirname .. ("../build/?.%s"):format(ext)
end

---@type fun(s: string): string
local trim_semicolon = function(s)
	return s:sub(-1) == ";" and s:sub(1, -2) or s
end

M.load = function()
	local path = library_path()
	if not string.find(package.cpath, path, 1, true) then
		package.cpath = trim_semicolon(package.cpath) .. ";" .. path
	end
end

return M
