-- muse/init.lua — Muse library root module
-- Resolves the library's base directory at load time so all child modules
-- can construct correct filesystem paths, regardless of where Muse is
-- placed relative to the project root.
--
-- Usage from any Muse sub-module:
--   local muse = require("init")
--   local path = muse.resolve("ui/fonts/NotoSansSC-Regular.ttf")

local M = {}

do
	-- debug.getinfo(1, "S").source returns the file path of this module,
	-- e.g. "@muse/init.lua" or "lib/muse/init.lua".
	local src = debug.getinfo(1, "S").source:gsub("^@", "")
	M.root = src:match("(.*[/\\])") or ""
	-- Examples: "muse/", "lib/muse/", "" (if installed at project root)
end

--- Resolve a path relative to the Muse library root.
---@param relativePath string
---@return string absolute path from project root
function M.resolve(relativePath)
	return M.root .. relativePath
end

return M
