local Utils = {
	RENDER_LAYERS = {
		BASE = 0,
		OVERLAY = 50,
		DROPDOWN = 80,
		TOOLTIP = 100
	},
	TWO_PI = math.pi * 2,
	TEXT_WRAP_MODE = {
		OFF = "off",
		DEFAULT = "default"
	},
	TEXT_OVERFLOW_MODE = {
		NONE = "none", -- 不修剪文本
		CHAR = "char" -- 逐字符修剪文本
	},
	ANCHORS_HORI = {
		LEFT = "left",
		MIDDLE = "middle",
		RIGHT = "right"
	},
	ANCHORS_VERT = {
		TOP = "top",
		MIDDLE = "middle",
		BOTTOM = "bottom"
	},
	BTN_STATES = {
		NORMAL = "normal",
		PRESSED = "pressed",
		DISABLED = "disabled",
		SELECTED = "selected",
		HOVER = "hover",
		SELECTED_HOVER = "selected_hover"
	},
	ORIENTATION = {
		VERTICAL = "vertical",
		HORIZONTAL = "horizontal",
	},
	H_ALIGN = {
		LEFT = "left",
		CENTER = "center",
		RIGHT = "right",
		JUSTIFY = "justify",
	},
	V_ALIGN = {
		TOP = "top",
		CENTER = "center",
		BOTTOM = "bottom",
	},
	CROSS_ALIGN = {
		STRETCH = "stretch",
		START = "start",
		CENTER = "center",
		END = "end",
	},
	CHECKBOX_STYLE = {
		CHECKBOX = "checkbox",
		TOGGLE = "toggle",
	},
}

--- 构造颜色对象
---@param r number 红色通道的值 0~255
---@param g number 绿色通道的值 0~255
---@param b number 蓝色通道的值 0~255
---@param a number|nil 不透明度通道的值 0~1 默认为 1
function Utils.RGB(r, g, b, a)
	return {r / 255, g / 255, b / 255, a or 1}
end

local grayscale_colors = {
	light = Utils.RGB(240, 240, 240),
	light_gray1 = Utils.RGB(200, 200, 200),
	light_gray2 = Utils.RGB(155, 155, 155),
	light_gray3 = Utils.RGB(100, 100, 100),
	dark_gray1 = Utils.RGB(70, 70, 70),
	dark_gray2 = Utils.RGB(50, 50, 50),
	dark_gray3 = Utils.RGB(38, 38, 38),
	dark = Utils.RGB(26, 26, 26)
}
Utils.UI_COLORS = {
	WHITE = Utils.RGB(255, 255, 255),
	BG = grayscale_colors.dark,
	SURFACE = grayscale_colors.dark_gray2,
	LINE = grayscale_colors.dark_gray1,

	TITLE = grayscale_colors.light,
	PRIMARY_TEXT = grayscale_colors.light_gray1,
	SECONDARY_TEXT = grayscale_colors.light_gray3,
	HINT = grayscale_colors.light_gray2,

	BTN_NORMAL = grayscale_colors.dark_gray3,
	BTN_HOVER = grayscale_colors.dark_gray1,
	BTN_DISABLED = grayscale_colors.dark_gray2,
	BTN_SELECTED = Utils.RGB(70, 110, 170, 0.30),
	BTN_SELECTED_HOVER = Utils.RGB(70, 110, 170, 0.45),

	ACCENT = Utils.RGB(80, 120, 180),
	ACCENT_LIGHT = Utils.RGB(100, 145, 210),
	WARNING = Utils.RGB(210, 170, 80),

	-- 旧名称兼容
	PINK = Utils.RGB(80, 120, 180),
	LIGHT_PINK = Utils.RGB(100, 145, 210),
	BLUE = Utils.RGB(80, 120, 180),
	LIGHT_BLUE = Utils.RGB(100, 145, 210),
	YELLOW = Utils.RGB(210, 170, 80)
}

--- 创建一个按钮状态的样式定义
---@param text string|table|nil 接受coloredtext
---@param text_color table|nil
---@param font_size number|nil
---@param bg_color table|nil
---@param outline_width number|nil
---@param outline_color table|nil
---@param offset table|nil {x offset, y offset}
---@param scale table|nil {x scale, y scale}
---@param rounding_radius number|nil 背景矩形的圆角半径
function Utils.newButtonStateStyle(text, text_color, font_size, bg_color, outline_width, outline_color, offset, scale,
	rounding_radius)
	return {
		text = text,
		text_color = text_color,
		font_size = font_size,
		bg_color = bg_color,
		outline_width = outline_width,
		outline_color = outline_color,
		offset = offset,
		scale = scale,
		rounding_radius = rounding_radius
	}
end

--- 创建一个图片按钮状态的样式定义
---@param texture love.Texture|nil
---@param tint table|nil
---@param text string|table|nil 接受coloredtext
---@param text_color table|nil
---@param font_size number|nil
---@param offset table|nil {x offset, y offset}
---@param scale table|nil {x scale, y scale}
function Utils.newImageButtonStateStyle(texture, tint, text, text_color, font_size, offset, scale)
	return {
		text = text,
		text_color = text_color,
		font_size = font_size,
		texture = texture,
		tint = tint,
		offset = offset,
		scale = scale
	}
end

function Utils.clamp(val, min, max)
	return math.max(min, math.min(val, max))
end

--- 校验枚举值，非法时使用默认值并打印警告
---@param value any 待校验的值
---@param enum table 枚举常量表（如 Utils.ORIENTATION）
---@param default any 非法时的回退值
---@param label string 调用方名称（用于警告信息）
function Utils.validateEnum(value, enum, default, label)
	if value == nil then
		return default
	end
	for _, v in pairs(enum) do
		if v == value then
			return value
		end
	end
	print(string.format("%s: invalid value '%s', using default '%s'", label, tostring(value), tostring(default)))
	return default
end

return Utils
