--------------------------------------------------
-- json.lua — 轻量 JSON 编解码
-- 仅处理标准 JSON 子集：null, bool, number, string, array, object
-- 不依赖任何外部库，适配 Lua 5.1 (LuaJIT)
--------------------------------------------------

local Json = {}

--------------------------------------------------
-- 编码（Lua → JSON 字符串）
--------------------------------------------------

-- 前向声明：encodeValue / encodeTable 互相递归调用
local encodeValue, encodeTable

function encodeValue(v, indent, level, pretty)
	local t = type(v)
	if t == "nil" then
		return "null"
	elseif t == "boolean" then
		return v and "true" or "false"
	elseif t == "number" then
		if v == math.floor(v) and math.abs(v) < 1e14 then
			return string.format("%d", v)
		end
		return string.format("%.4f", v)
	elseif t == "string" then
		return string.format("%q", v)
	elseif t == "table" then
		return encodeTable(v, indent, level, pretty)
	end
	return "null"
end

local function isArray(t)
	if next(t) == nil then return false end
	local count = 0
	for k, _ in pairs(t) do
		if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
			return false
		end
		count = count + 1
	end
	for i = 1, count do
		if t[i] == nil then return false end
	end
	return true
end

local function encodeTable(t, indent, level, pretty)
	if not pretty then
		if isArray(t) then
			local parts = {}
			for i = 1, #t do
				parts[i] = encodeValue(t[i], "", 0, false)
			end
			return "[" .. table.concat(parts, ",") .. "]"
		else
			local parts = {}
			local keys = {}
			for k in pairs(t) do table.insert(keys, k) end
			table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
			for _, k in ipairs(keys) do
				local ek = (type(k) == "string") and string.format("%q", k) or ("[" .. tostring(k) .. "]")
				table.insert(parts, ek .. ":" .. encodeValue(t[k], "", 0, false))
			end
			return "{" .. table.concat(parts, ",") .. "}"
		end
	end

	-- pretty
	local next_level = level + 1
	local pad = string.rep(indent, level)
	local inner_pad = string.rep(indent, next_level)

	if isArray(t) then
		if #t == 0 then return "[]" end
		local lines = {}
		for i = 1, #t do
			table.insert(lines, inner_pad .. encodeValue(t[i], indent, next_level, true))
		end
		return "[\n" .. table.concat(lines, ",\n") .. "\n" .. pad .. "]"
	else
		local keys = {}
		for k in pairs(t) do table.insert(keys, k) end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		if #keys == 0 then return "{}" end
		local lines = {}
		for _, k in ipairs(keys) do
			local ek = (type(k) == "string") and string.format("%q", k) or ("[" .. tostring(k) .. "]")
			local ev = encodeValue(t[k], indent, next_level, true)
			table.insert(lines, inner_pad .. ek .. ": " .. ev)
		end
		return "{\n" .. table.concat(lines, ",\n") .. "\n" .. pad .. "}"
	end
end

function Json.encode(value, pretty)
	if pretty == nil then pretty = true end
	return encodeValue(value, "  ", 0, pretty)
end

--------------------------------------------------
-- 解码（JSON 字符串 → Lua table）
--------------------------------------------------

local function skipWhitespace(s, pos)
	while pos <= #s do
		local c = s:sub(pos, pos)
		if c ~= " " and c ~= "\t" and c ~= "\n" and c ~= "\r" then
			break
		end
		pos = pos + 1
	end
	return pos
end

local function parseValue(s, pos)
	pos = skipWhitespace(s, pos)
	if pos > #s then
		error("unexpected end of JSON at pos " .. pos)
	end
	local c = s:sub(pos, pos)
	if c == "{" then
		return parseObject(s, pos)
	elseif c == "[" then
		return parseArray(s, pos)
	elseif c == '"' then
		return parseString(s, pos)
	elseif c == "t" or c == "f" then
		return parseBool(s, pos)
	elseif c == "n" then
		return parseNull(s, pos)
	elseif c == "-" or (c >= "0" and c <= "9") then
		return parseNumber(s, pos)
	else
		error("unexpected character '" .. c .. "' at pos " .. pos)
	end
end

local function parseObject(s, pos)
	pos = pos + 1 -- skip '{'
	local obj = {}
	pos = skipWhitespace(s, pos)
	if s:sub(pos, pos) == "}" then
		return obj, pos + 1
	end
	while true do
		pos = skipWhitespace(s, pos)
		local key
		key, pos = parseString(s, pos)
		pos = skipWhitespace(s, pos)
		if s:sub(pos, pos) ~= ":" then
			error("expected ':' at pos " .. pos)
		end
		pos = pos + 1
		local val
		val, pos = parseValue(s, pos)
		obj[key] = val
		pos = skipWhitespace(s, pos)
		local c = s:sub(pos, pos)
		if c == "}" then
			return obj, pos + 1
		elseif c == "," then
			pos = pos + 1
		else
			error("expected ',' or '}' at pos " .. pos .. ", got '" .. c .. "'")
		end
	end
end

local function parseArray(s, pos)
	pos = pos + 1 -- skip '['
	local arr = {}
	pos = skipWhitespace(s, pos)
	if s:sub(pos, pos) == "]" then
		return arr, pos + 1
	end
	while true do
		local val
		val, pos = parseValue(s, pos)
		arr[#arr + 1] = val
		pos = skipWhitespace(s, pos)
		local c = s:sub(pos, pos)
		if c == "]" then
			return arr, pos + 1
		elseif c == "," then
			pos = pos + 1
		else
			error("expected ',' or ']' at pos " .. pos .. ", got '" .. c .. "'")
		end
	end
end

local function parseString(s, pos)
	pos = pos + 1 -- skip '"'
	local parts = {}
	while pos <= #s do
		local c = s:sub(pos, pos)
		if c == "\\" then
			pos = pos + 1
			local esc = s:sub(pos, pos)
			if esc == '"' or esc == "\\" or esc == "/" then
				parts[#parts + 1] = esc
			elseif esc == "n" then
				parts[#parts + 1] = "\n"
			elseif esc == "r" then
				parts[#parts + 1] = "\r"
			elseif esc == "t" then
				parts[#parts + 1] = "\t"
			elseif esc == "b" then
				parts[#parts + 1] = "\b"
			elseif esc == "f" then
				parts[#parts + 1] = "\f"
			elseif esc == "u" then
				local hex = s:sub(pos + 1, pos + 4)
				local codepoint = tonumber(hex, 16)
				if codepoint then
					parts[#parts + 1] = utf8.char(codepoint)
				end
				pos = pos + 4
			else
				parts[#parts + 1] = esc
			end
			pos = pos + 1
		elseif c == '"' then
			return table.concat(parts), pos + 1
		else
			parts[#parts + 1] = c
			pos = pos + 1
		end
	end
	error("unterminated string at pos " .. pos)
end

local function parseNumber(s, pos)
	local start = pos
	if s:sub(pos, pos) == "-" then
		pos = pos + 1
	end
	while pos <= #s and s:sub(pos, pos) >= "0" and s:sub(pos, pos) <= "9" do
		pos = pos + 1
	end
	if s:sub(pos, pos) == "." then
		pos = pos + 1
		while pos <= #s and s:sub(pos, pos) >= "0" and s:sub(pos, pos) <= "9" do
			pos = pos + 1
		end
	end
	if s:sub(pos, pos) == "e" or s:sub(pos, pos) == "E" then
		pos = pos + 1
		if s:sub(pos, pos) == "+" or s:sub(pos, pos) == "-" then
			pos = pos + 1
		end
		while pos <= #s and s:sub(pos, pos) >= "0" and s:sub(pos, pos) <= "9" do
			pos = pos + 1
		end
	end
	local numStr = s:sub(start, pos - 1)
	return tonumber(numStr), pos
end

local function parseBool(s, pos)
	if s:sub(pos, pos + 3) == "true" then
		return true, pos + 4
	elseif s:sub(pos, pos + 4) == "false" then
		return false, pos + 5
	end
	error("expected 'true' or 'false' at pos " .. pos)
end

local function parseNull(s, pos)
	if s:sub(pos, pos + 3) == "null" then
		return json_null, pos + 4
	end
	error("expected 'null' at pos " .. pos)
end

function Json.decode(str)
	if str == nil or str == "" then return nil end
	local ok, result = pcall(function()
		local val, pos = parseValue(str, 1)
		pos = skipWhitespace(str, pos)
		if pos <= #str then
			error("trailing content at pos " .. pos)
		end
		return val
	end)
	if not ok then
		print("json.decode error: " .. tostring(result))
		return nil
	end
	return result
end

--- 从文件读取并解码 JSON
function Json.load(path)
	local file, err = io.open(path, "r")
	if not file then
		print("json.load: " .. tostring(err))
		return nil
	end
	local content = file:read("*a")
	file:close()
	return Json.decode(content)
end

return Json
