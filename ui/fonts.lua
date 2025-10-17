local Fonts = {
	default = {
		_file = "ui/fonts/NotoSansSC-Regular.ttf",
		[16] = love.graphics.newFont("ui/fonts/NotoSansSC-Regular.ttf", 16),
	},
	default_thin = {
		_file = "ui/fonts/NotoSansSC-Thin.ttf",
	},
	default_light = {
		_file = "ui/fonts/NotoSansSC-Light.ttf",
	},
	default_bold = {
		_file = "ui/fonts/NotoSansSC-Bold.ttf",
	},
	default_black = {
		_file = "ui/fonts/NotoSansSC-Black.ttf",
	},
	debug = {
		_file = "ui/fonts/NotoSansSC-Light.ttf",
	},
}



---@param key string
---@param size number
function Fonts:getFont(key, size)
	local font = self[key][size]
	if not font then
		font = love.graphics.newFont(self[key]._file, size)
		self[key][size] = font
	end
	return font
end

function Fonts:hasFont(key)
	return self[key] ~= nil
end


return Fonts