local Fonts = {
	default = {
		_file = "ui/fonts/NotoSansSC-VariableFont_wght.ttf",
		[16] = love.graphics.newFont("ui/fonts/NotoSansSC-VariableFont_wght.ttf", 16),
	}
}


function Fonts:GetFont(key, size)
	if not self[key] or type(size) ~= "number" then
		return
	end
	local font = self[key][size]
	if not font then
		font = love.graphics.newFont(self[key]._file, size)
		self[key][size] = font
	end
	return font
end


return Fonts