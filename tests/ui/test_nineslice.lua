local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Image = require "ui.widgets.image"
local NineSlice = require "ui.widgets.nineslice"
local Utils = require "ui.utils"

local test = {}
test.name = "NineSlice"

function test.create(parent)
	parent:removeAllChildren()

	local tex = love.graphics.newImage("assets/example_image_128x128.png")
	-- center_padding: 32px 的边框保持原始大小，中间 64×64 区域被拉伸
	local pad = {32, 32, 32, 32}

	parent:addChild(Text({
		text = "NineSlice — 同一纹理在不同尺寸下的九宫格拉伸效果",
		font_size = 14, h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 0},
	}))

	parent:addChild(Text({
		text = "center_padding = {32, 32, 32, 32}  四角保持原尺寸，四边单向拉伸，中心双向拉伸",
		font_size = 11, h = 14,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 24, 0},
	}))

	--------------------------------------------------
	-- Row 1: 原始图 + 比原图小 + 接近原图大小
	--------------------------------------------------
	local row1 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 44, 0}, h = 170,
	}))

	-- 原始纹理（非 NineSlice，作为对照）
	row1:addChild(Text({
		text = "原图\n(128×128)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {14, 0, 0},
	}))
	local ref = row1:addChild(Image({
		texture = tex, use_texture_size = true,
		anchor = {0, 0, 0, 0}, padding = {14, 0, 30, 0},
	}))
	ref:enableDebug(true)

	-- 九宫格 小尺寸（80×80 — 比原图小，四角 32px 会占主导）
	row1:addChild(Text({
		text = "NineSlice 小\n(80×80)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {160, 0, 0},
	}))
	local ns_small = row1:addChild(NineSlice({
		texture = tex, center_padding = pad,
		anchor = {0, 0, 0, 0}, w = 80, h = 80,
		padding = {160, 0, 30, 0},
	}))
	ns_small:enableDebug(true)

	-- 九宫格 接近原图（128×128 — 基本看不出拉伸）
	row1:addChild(Text({
		text = "NineSlice 原寸\n(128×128)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {258, 0, 0},
	}))
	local ns_native = row1:addChild(NineSlice({
		texture = tex, center_padding = pad,
		anchor = {0, 0, 0, 0}, w = 128, h = 128,
		padding = {258, 0, 30, 0},
	}))
	ns_native:enableDebug(true)

	-- 九宫格 大尺寸（200×200 — 中心区域明显拉伸）
	row1:addChild(Text({
		text = "NineSlice 放大\n(200×200)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {404, 0, 0},
	}))
	local ns_big = row1:addChild(NineSlice({
		texture = tex, center_padding = pad,
		anchor = {0, 0, 0, 0}, w = 200, h = 200,
		padding = {404, 0, 30, 0},
	}))
	ns_big:enableDebug(true)

	--------------------------------------------------
	-- Row 2: 不同宽高比 + 非对称 padding
	--------------------------------------------------
	local pad2 = {16, 48, 48, 16} -- 左16 右48 上48 下16（非对称）
	local row2 = parent:addChild(Widget({
		anchor = {0, 0, 1, 1}, padding = {0, 0, 222, 0},
	}))

	row2:addChild(Text({
		text = string.format("非对称 padding = {%d, %d, %d, %d}  方向性拉伸：", pad2[1], pad2[2], pad2[3], pad2[4]),
		font_size = 11, h = 14,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 0},
	}))

	-- 扁平横幅（宽 >> 高）
	row2:addChild(Text({
		text = "扁平横幅\n(360×60)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {4, 0, 22, 0},
	}))
	local ns_wide = row2:addChild(NineSlice({
		texture = tex, center_padding = pad2,
		anchor = {0, 0, 0, 0}, w = 360, h = 60,
		padding = {4, 0, 48, 0},
	}))
	ns_wide:enableDebug(true)

	-- 竖长面板（高 >> 宽）
	row2:addChild(Text({
		text = "竖长面板\n(90×200)",
		font_size = 10, h = 24,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {4, 0, 72, 0},
	}))
	local ns_tall = row2:addChild(NineSlice({
		texture = tex, center_padding = pad2,
		anchor = {0, 0, 0, 0}, w = 90, h = 200,
		padding = {380, 0, 30, 0},
	}))
	ns_tall:enableDebug(true)

	-- 极小 NineSlice（比边框总和小）
	row2:addChild(Text({
		text = "极小尺寸\n(50×50)\n边框主导",
		font_size = 10, h = 36,
		text_color = Utils.UI_COLORS.HINT,
		anchor = {0, 0, 0, 0}, padding = {488, 0, 48, 0},
	}))
	local ns_mini = row2:addChild(NineSlice({
		texture = tex, center_padding = pad,
		anchor = {0, 0, 0, 0}, w = 50, h = 50,
		padding = {488, 0, 86, 0},
	}))
	ns_mini:enableDebug(true)
end

return test
