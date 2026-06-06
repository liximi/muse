local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Image = require "ui.widgets.image"
local ImageButton = require "ui.widgets.imagebutton"
local Panel = require "ui.widgets.panel"
local Utils = require "ui.utils"

local test = {}
test.name = "Image"

function test.create(parent)
	parent:removeAllChildren()

	local tex = love.graphics.newImage("assets/example_image_128x128.png")

	parent:addChild(Text({
		text = "Image — 纹理显示、tint 着色、Transform 变换、ImageButton",
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
	local native_label = row1:addChild(Text({
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
	local fixed_label = row1:addChild(Text({
		text = "固定尺寸\n(w=64, h=48)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {158, 0, 0},
	}))
	local fixed_img = row1:addChild(Image({
		texture = tex, w = 64, h = 48,
		anchor = {0, 0, 0, 0}, padding = {158, 0, 26, 0},
	}))
	fixed_img:enableDebug(true)

	-- 放大（比原图大）
	local big_label = row1:addChild(Text({
		text = "放大\n(w=192, h=128)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {240, 0, 0},
	}))
	local big_img = row1:addChild(Image({
		texture = tex, w = 192, h = 128,
		anchor = {0, 0, 0, 0}, padding = {240, 0, 26, 0},
	}))
	big_img:enableDebug(true)

	-- tint 着色
	local tint_label = row1:addChild(Text({
		text = "tint 着色\n(红色叠加)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {450, 0, 0},
	}))
	local tint_img = row1:addChild(Image({
		texture = tex,
		tint = {0.9, 0.3, 0.3, 0.7},
		use_texture_size = true,
		anchor = {0, 0, 0, 0}, padding = {450, 0, 26, 0},
	}))
	tint_img:enableDebug(true)

	--------------------------------------------------
	-- Row 2: 旋转 / 缩放 / 正常尺寸的 measure 验证
	--------------------------------------------------
	local row2 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 198, 0}, h = 160,
	}))

	-- 旋转 25°
	local rot_label = row2:addChild(Text({
		text = "旋转 25°\n(pivot 0.5,0.5)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {14, 0, 0},
	}))
	local rot_img = row2:addChild(Image({
		texture = tex, use_texture_size = true,
		pivot = {0.5, 0.5},
		r = math.rad(25),
		anchor = {0, 0, 0, 0},
		padding = {14 + 64, 0, 26 + 64, 0},
	}))
	rot_img:enableDebug(true)

	-- 缩放 0.5x
	local scale_label = row2:addChild(Text({
		text = "缩放 0.5x",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {224, 0, 0},
	}))
	local scale_img = row2:addChild(Image({
		texture = tex, use_texture_size = true,
		sx = 0.5, sy = 0.5,
		anchor = {0, 0, 0, 0},
		padding = {224, 0, 26, 0},
	}))
	scale_img:enableDebug(true)

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

	--------------------------------------------------
	-- Row 3: ImageButton 演示
	--------------------------------------------------
	local row3 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 368, 0}, h = 60,
	}))

	row3:addChild(Text({
		text = "ImageButton — 图片按钮，含文字叠加、状态切换：",
		font_size = 12, h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 0},
	}))

	-- 正常状态 ImageButton
	local ibtn = row3:addChild(ImageButton({
		normal = Utils.newImageButtonStateStyle(tex, nil, "点击我"),
		hover = Utils.newImageButtonStateStyle(tex, {0.7, 0.7, 1, 1}, "悬停中"),
		pressed = Utils.newImageButtonStateStyle(tex, {0.5, 0.5, 0.8, 1}, "按下了!"),
		anchor = {0, 0, 0, 0},
		w = 160, h = 48,
		padding = {0, 0, 22, 0},
		on_click = function()
			print("ImageButton clicked!")
		end,
	}))
	ibtn:enableDebug(true)

	-- 无文字的 ImageButton（纯图片按钮）
	local ibtn2 = row3:addChild(ImageButton({
		normal = Utils.newImageButtonStateStyle(tex, nil, nil),
		hover = Utils.newImageButtonStateStyle(tex, {0.8, 0.8, 1, 1}, nil),
		pressed = Utils.newImageButtonStateStyle(tex, {0.5, 0.5, 0.9, 1}, nil),
		no_text = true,
		anchor = {0, 0, 0, 0},
		w = 48, h = 48,
		padding = {170, 0, 22, 0},
		on_click = function()
			print("Pure ImageButton clicked!")
		end,
	}))
	ibtn2:enableDebug(true)

	row3:addChild(Text({
		text = "← 有文字  |  纯图片 →",
		font_size = 12,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0},
		padding = {230, 0, 30, 0},
	}))
end

return test
