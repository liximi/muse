local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Image = require "ui.widgets.image"
local Panel = require "ui.widgets.panel"
local Utils = require "ui.utils"

local test = {}
test.name = "Image"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
	}))

	local tex = love.graphics.newImage("assets/example_image_128x128.png")

	parent:addChild(Text({
		text = "Image — 纹理显示、tint 着色、Transform 变换",
		font_size = 14, h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 0},
	}))

	--------------------------------------------------
	-- Row 1: 原始尺寸 / 显式尺寸 / tint 着色
	--------------------------------------------------
	local row1 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 28, 0}, h = 160,
	}))

	-- 使用纹理原始尺寸
	row1:addChild(Text({
		text = "原始尺寸\n(use_texture_size)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {14, 0, 0},
	}))
	local native_img = row1:addChild(Image({
		texture = tex, use_texture_size = true,
		anchor = {0, 0, 0, 0}, padding = {14, 0, 26, 0},
	}))
	native_img:enableDebug(true)

	-- 显式设固定尺寸（拉伸填充）
	row1:addChild(Text({
		text = "固定尺寸\n(w=64, h=48)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {158, 0, 0},
	}))
	row1:addChild(Image({
		texture = tex, w = 64, h = 48,
		anchor = {0, 0, 0, 0}, padding = {158, 0, 26, 0},
	})):enableDebug(true)

	-- 放大（比原图大）
	row1:addChild(Text({
		text = "放大\n(w=192, h=128)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {240, 0, 0},
	}))
	row1:addChild(Image({
		texture = tex, w = 192, h = 128,
		anchor = {0, 0, 0, 0}, padding = {240, 0, 26, 0},
	})):enableDebug(true)

	-- tint 着色
	row1:addChild(Text({
		text = "tint 着色\n(红色叠加)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {450, 0, 0},
	}))
	row1:addChild(Image({
		texture = tex,
		tint = {0.9, 0.3, 0.3, 0.7},
		use_texture_size = true,
		anchor = {0, 0, 0, 0}, padding = {450, 0, 26, 0},
	})):enableDebug(true)

	--------------------------------------------------
	-- Row 2: 旋转 / 缩放 / 图文组合
	--------------------------------------------------
	local row2 = parent:addChild(Widget({
		anchor = {0, 0, 1, 1}, padding = {0, 0, 198, 0},
	}))

	-- 旋转 25°
	row2:addChild(Text({
		text = "旋转 25°\n(pivot 0.5,0.5)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {14, 0, 0},
	}))
	row2:addChild(Image({
		texture = tex, use_texture_size = true,
		pivot = {0.5, 0.5},
		r = math.rad(25),
		anchor = {0, 0, 0, 0},
		padding = {14 + 64, 0, 26 + 64, 0},
	})):enableDebug(true)

	-- 缩放 0.5x
	row2:addChild(Text({
		text = "缩放 0.5x",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {224, 0, 0},
	}))
	row2:addChild(Image({
		texture = tex, use_texture_size = true,
		sx = 0.5, sy = 0.5,
		anchor = {0, 0, 0, 0},
		padding = {224, 0, 26, 0},
	})):enableDebug(true)

	-- 图片配文字说明（模拟图标+文本）
	local icon_panel = row2:addChild(Panel({
		bg_color = {0.15, 0.15, 0.17, 1},
		rounding_radius = 6,
		outline_width = 1,
		outline_color = Utils.UI_COLORS.LINE,
		anchor = {0, 0, 0, 0},
		w = 180, h = 110,
		padding = {350, 0, 26, 0},
	}))
	icon_panel:addChild(Image({
		texture = tex,
		w = 48, h = 48,
		anchor = {0, 0, 0, 0},
		pivot = {0.5, 0},
		padding = {90, 0, 12, 0},
	}))
	icon_panel:addChild(Text({
		text = "图标 + 文本\nImage 作图标使用",
		font_size = 12,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		h_align = "center",
		anchor = {0, 0, 1, 0},
		padding = {8, 8, 68, 0},
	}))
end

return test
