local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Utils = require "ui.utils"

local test = {}
test.name = "Transform Features"

function test.create(parent)
	parent:removeAllChildren()

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	parent:addChild(Text({
		text = "Transform — 锚点 / Pivot / 旋转 / 嵌套坐标链",
		font_size = 14,
		h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 0}
	}))

	--------------------------------------------------
	-- Demo 1: 锚点模式对比
	--------------------------------------------------
	local demo1 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 28, 0},
		h = 130
	}))

	demo1:addChild(Text({
		text = "点锚点 (anchor center) vs 拉伸锚点 (anchor stretch)",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0}
	}))

	-- 点锚点：固定尺寸，位于左上
	local pt_anchor = demo1:addChild(Panel({
		bg_color = Utils.RGB(80, 120, 180, 0.6),
		outline_width = 1,
		outline_color = Utils.UI_COLORS.ACCENT,
		anchor = {0, 0, 0, 0},
		w = 120,
		h = 60,
		padding = {0, 0, 20, 0}
	}))
	pt_anchor:addChild(Text({
		text = "point\nw=120 h=60",
		font_size = 11,
		text_color = Utils.UI_COLORS.TITLE,
		anchor = {0, 0, 1, 1},
		padding = {4, 4, 4, 4}
	}))
	pt_anchor:enableDebug(true)

	-- 拉伸锚点：填充右侧剩余空间
	local st_anchor = demo1:addChild(Panel({
		bg_color = Utils.RGB(210, 170, 80, 0.4),
		outline_width = 1,
		outline_color = Utils.UI_COLORS.WARNING,
		anchor = {0, 0, 1, 1},
		padding = {130, 0, 20, 40}
	}))
	st_anchor:addChild(Text({
		text = "stretch\nfill rest",
		font_size = 11,
		text_color = Utils.UI_COLORS.TITLE,
		anchor = {0, 0, 1, 1},
		padding = {4, 4, 4, 4}
	}))
	st_anchor:enableDebug(true)

	--------------------------------------------------
	-- Demo 2: Pivot + 旋转
	--------------------------------------------------
	local demo2 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 166, 0},
		h = 120
	}))

	demo2:addChild(Text({
		text = "Pivot 旋转: 左上角 pivot{0,0} / 中心 pivot{0.5,0.5} / 右下角 pivot{1,1}",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0}
	}))

	local colors = {Utils.RGB(80, 150, 200, 0.7), Utils.RGB(200, 120, 80, 0.7), Utils.RGB(100, 180, 100, 0.7)}
	local pivots = {{0, 0}, {0.5, 0.5}, {1, 1}}
	local labels = {"pivot 0,0", "pivot 0.5,0.5", "pivot 1,1"}

	for i = 1, 3 do
		local x = 20 + (i - 1) * 160
		local p = demo2:addChild(Panel({
			bg_color = colors[i],
			outline_width = 1,
			outline_color = Utils.UI_COLORS.TITLE,
			anchor = {0, 0, 0, 0},
			pivot = pivots[i],
			w = 100,
			h = 50,
			r = 0.35,
			padding = {x, 0, 24, 0}
		}))
		p:addChild(Text({
			text = labels[i],
			font_size = 10,
			text_color = Utils.UI_COLORS.TITLE,
			anchor = {0, 0, 1, 1},
			padding = {2, 2, 2, 2}
		}))
		p:enableDebug(true)
	end

	--------------------------------------------------
	-- Demo 3: 嵌套坐标链
	--------------------------------------------------
	local demo3 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 294, 0},
		h = 130
	}))

	demo3:addChild(Text({
		text = "嵌套坐标链: parent(scale=1.5, rot) -> child(offset) -> grandchild(offset)",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0}
	}))

	-- 祖父
	local g_parent = demo3:addChild(Panel({
		bg_color = Utils.RGB(100, 100, 100, 0.5),
		outline_width = 2,
		outline_color = Utils.UI_COLORS.PINK,
		anchor = {0, 0, 0, 0},
		w = 200,
		h = 100,
		padding = {20, 0, 22, 0}
	}))
	g_parent:enableDebug(true)
	g_parent.transform:setScale(1.5, 1.5)

	-- 父
	local g_child = g_parent:addChild(Panel({
		bg_color = Utils.RGB(80, 120, 180, 0.6),
		outline_width = 1,
		outline_color = Utils.UI_COLORS.ACCENT,
		anchor = {0, 0, 0, 0},
		w = 120,
		h = 60,
		padding = {30, 0, 10, 0}
	}))
	g_child:addChild(Text({
		text = "parent\nscale 1.5",
		font_size = 9,
		text_color = Utils.UI_COLORS.TITLE,
		anchor = {0, 0, 1, 1}
	}))
	g_child:enableDebug(true)

	-- 孙
	local g_grand = g_child:addChild(Panel({
		bg_color = Utils.RGB(200, 170, 80, 0.7),
		outline_width = 1,
		outline_color = Utils.UI_COLORS.WARNING,
		anchor = {0, 0, 0, 0},
		w = 60,
		h = 30,
		padding = {30, 0, 5, 0}
	}))
	g_grand:addChild(Text({
		text = "grand",
		font_size = 9,
		text_color = Utils.UI_COLORS.TITLE,
		anchor = {0, 0, 1, 1}
	}))
	g_grand:enableDebug(true)

	--------------------------------------------------
	-- Demo 4: Padding 效果
	--------------------------------------------------
	local demo4 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0},
		padding = {0, 0, 432, 0},
		h = 120
	}))

	demo4:addChild(Text({
		text = "Padding 效果: anchor{0,0,1,0} + 不同 left padding",
		font_size = 12,
		h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0}
	}))

	-- 一个拉伸锚点的容器，展示 padding 如何分割空间
	local pad_container = demo4:addChild(Panel({
		bg_color = Utils.RGB(50, 50, 50, 0.5),
		outline_width = 1,
		outline_color = Utils.UI_COLORS.LINE,
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 22, 20}
	}))
	pad_container:enableDebug(true)

	for i = 1, 3 do
		pad_container:addChild(Panel({
			bg_color = Utils.RGB(80 + i * 30, 100 + i * 30, 180 - i * 30, 0.7),
			outline_width = 1,
			outline_color = Utils.UI_COLORS.LINE,
			anchor = {(i - 1) / 3, 0, i / 3, 1},
			padding = {4, 4, 4, 4}
		}))
	end
end

return test
