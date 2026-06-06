local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local SliderBar = require "ui.widgets.sliderbar"
local Utils = require "ui.utils"

local test = {}
test.name = "Transform Features"

function test.create(parent)
	parent:removeAllChildren()

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	parent:addChild(Text({
		text = "Transform — 动态演示: 旋转 / 缩放 / 轨道 / 交互控制",
		font_size = 14, h = 20,
		text_color = Utils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0}, padding = {0, 0, 0},
	}))

	--------------------------------------------------
	-- Demo 1: 锚点模式对比 (静态)
	--------------------------------------------------
	local demo1 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 28, 0}, h = 100,
	}))

	demo1:addChild(Text({
		text = "锚点对比: 点锚点(w=120) vs 拉伸锚点(自适应填充)",
		font_size = 12, h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0},
	}))

	local pt = demo1:addChild(Panel({
		bg_color = Utils.RGB(80, 120, 180, 0.6), outline_width = 1,
		outline_color = Utils.UI_COLORS.ACCENT,
		anchor = {0, 0, 0, 0}, w = 120, h = 50,
		padding = {0, 0, 20, 0},
	}))
	pt:addChild(Text({text = "point", font_size = 10, text_color = Utils.UI_COLORS.TITLE, anchor = {0, 0, 1, 1}, padding = {4, 4, 4, 4}}))
	pt:enableDebug(true)

	local st = demo1:addChild(Panel({
		bg_color = Utils.RGB(210, 170, 80, 0.4), outline_width = 1,
		outline_color = Utils.UI_COLORS.WARNING,
		anchor = {0, 0, 1, 1}, padding = {130, 0, 20, 30},
	}))
	st:addChild(Text({text = "stretch", font_size = 10, text_color = Utils.UI_COLORS.TITLE, anchor = {0, 0, 1, 1}, padding = {4, 4, 4, 4}}))
	st:enableDebug(true)

	--------------------------------------------------
	-- Demo 2: 动态旋转 — 不同 pivot 持续自转
	--------------------------------------------------
	local demo2 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 136, 0}, h = 110,
	}))

	demo2:addChild(Text({
		text = "动态旋转: pivot{0,0} / pivot{0.5,0.5} / pivot{1,1} — debug 框可见 pivot 位置差异",
		font_size = 12, h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0},
	}))

	local colors2 = {Utils.RGB(80, 150, 200, 0.7), Utils.RGB(200, 120, 80, 0.7), Utils.RGB(100, 180, 100, 0.7)}
	local pivots2 = {{0, 0}, {0.5, 0.5}, {1, 1}}
	local labels2 = {"pivot 0,0", "pivot 0.5,0.5", "pivot 1,1"}

	for i = 1, 3 do
		local x = 20 + (i - 1) * 200
		local p = demo2:addChild(Panel({
			bg_color = colors2[i], outline_width = 1,
			outline_color = Utils.UI_COLORS.TITLE,
			anchor = {0, 0, 0, 0}, pivot = pivots2[i],
			w = 80, h = 50,
			padding = {x, 0, 22, 0},
		}))
		p:addChild(Text({text = labels2[i], font_size = 9, text_color = Utils.UI_COLORS.TITLE, anchor = {0, 0, 1, 1}, padding = {2, 2, 2, 2}}))
		p:enableDebug(true)

		-- 持续旋转：1 秒一圈
		p.onUpdate = function(_self, dt)
			local r = _self.transform:getGlobalRotation() + dt * math.pi
			_self.transform:setRotation(r)
		end
	end

	--------------------------------------------------
	-- Demo 3: 轨道 — 父旋转，子跟随
	--------------------------------------------------
	local demo3 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 254, 0}, h = 140,
	}))

	demo3:addChild(Text({
		text = "轨道: 父持续旋转，子相对父固定偏移 — getGlobalPosition 随父旋转联动",
		font_size = 12, h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0},
	}))

	-- 父：中央的大矩形，持续旋转
	local orbit_parent = demo3:addChild(Panel({
		bg_color = Utils.RGB(120, 120, 120, 0.4), outline_width = 1,
		outline_color = Utils.UI_COLORS.LINE,
		anchor = {0.3, 0, 0.7, 1}, padding = {0, 0, 26, 20},
	}))
	orbit_parent:enableDebug(true)

	orbit_parent.onUpdate = function(_self, dt)
		local r = _self.transform:getGlobalRotation() + dt * 0.8
		_self.transform:setRotation(r)
	end

	-- 子：贴在父内部右侧
	local moon = orbit_parent:addChild(Panel({
		bg_color = Utils.RGB(200, 170, 80, 0.8), outline_width = 1,
		outline_color = Utils.UI_COLORS.WARNING,
		anchor = {0.6, 0.2, 0, 0}, w = 30, h = 30,
		padding = {0, 0, 0, 0},
	}))
	moon:enableDebug(true)

	-- 孙：贴在 moon 内部
	local moon2 = moon:addChild(Panel({
		bg_color = Utils.RGB(200, 80, 80, 0.9), outline_width = 1,
		outline_color = Utils.UI_COLORS.ACCENT,
		anchor = {0, 0, 0, 0}, w = 12, h = 12,
		padding = {10, 0, 10, 0},
	}))
	moon2:enableDebug(true)

	--------------------------------------------------
	-- Demo 4: 缩放脉冲
	--------------------------------------------------
	local demo4 = parent:addChild(Widget({
		anchor = {0, 0, 1, 0}, padding = {0, 0, 402, 0}, h = 110,
	}))

	demo4:addChild(Text({
		text = "缩放脉冲: sin 波驱动 scale 在 0.6~1.4 之间振荡",
		font_size = 12, h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0},
	}))

	local scale_timer = {0, math.pi * 0.7, math.pi * 1.4}
	local scale_colors = {Utils.RGB(80, 150, 200, 0.7), Utils.RGB(200, 120, 80, 0.7), Utils.RGB(100, 180, 100, 0.7)}

	for i = 1, 3 do
		local x = 20 + (i - 1) * 200
		local p = demo4:addChild(Panel({
			bg_color = scale_colors[i], outline_width = 1,
			outline_color = Utils.UI_COLORS.TITLE,
			anchor = {0, 0, 0, 0}, pivot = {0.5, 0.5},
			w = 60, h = 60,
			r = i * 0.1,
			padding = {x + 30, 0, 24, 0},
		}))
		p:addChild(Text({text = string.format("p%d", i), font_size = 9, text_color = Utils.UI_COLORS.TITLE, anchor = {0, 0, 1, 1}, padding = {2, 2, 2, 2}}))
		p:enableDebug(true)

		local phase = scale_timer[i]
		p.onUpdate = function(_self, dt)
			phase = phase + dt * 2.5
			local s = 1.0 + 0.4 * math.sin(phase)
			_self.transform:setScale(s, s)
		end
	end

	--------------------------------------------------
	-- Demo 5: 交互控制 — 滑块实时控制旋转/缩放/位置
	--------------------------------------------------
	local demo5 = parent:addChild(Widget({
		anchor = {0, 0, 1, 1}, padding = {0, 0, 520, 0},
	}))

	demo5:addChild(Text({
		text = "交互控制: 拖动滑块改变目标矩形的旋转/缩放/X偏移",
		font_size = 12, h = 16,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 1, 0},
	}))

	-- 目标矩形
	local target = demo5:addChild(Panel({
		bg_color = Utils.RGB(80, 180, 120, 0.8), outline_width = 2,
		outline_color = Utils.UI_COLORS.TITLE,
		anchor = {0, 0, 0, 0}, pivot = {0.5, 0.5},
		w = 100, h = 60,
		padding = {300, 0, 30, 0},
	}))
	target:addChild(Text({text = "target", font_size = 11, text_color = Utils.UI_COLORS.TITLE, anchor = {0, 0, 1, 1}, padding = {2, 2, 2, 2}}))
	target:enableDebug(true)

	-- 旋转滑块
	local slider_y = 100
	demo5:addChild(Text({
		text = "旋转 (0~360度)", font_size = 11, h = 14,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 0, 0}, padding = {0, 0, slider_y, 0},
	}))

	demo5:addChild(SliderBar({
		orientation = "horizontal",
		anchor = {0, 0, 0.8, 0}, padding = {0, 0, slider_y + 16, 0}, h = 16,
		max_limit = 360,
		on_value_update = function(val, percent)
			target.transform:setRotation(val * math.pi / 180)
		end,
	}))

	-- 缩放滑块
	slider_y = slider_y + 40
	demo5:addChild(Text({
		text = "缩放 (0.3~2.0)", font_size = 11, h = 14,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 0, 0}, padding = {0, 0, slider_y, 0},
	}))

	demo5:addChild(SliderBar({
		orientation = "horizontal",
		anchor = {0, 0, 0.8, 0}, padding = {0, 0, slider_y + 16, 0}, h = 16,
		max_limit = 170, block_length_percent = 0.05,
		on_value_update = function(val, percent)
			local s = 0.3 + val / 100
			target.transform:setScale(s, s)
		end,
	}))

	-- X 偏移滑块
	slider_y = slider_y + 40
	demo5:addChild(Text({
		text = "X 偏移 (0~400)", font_size = 11, h = 14,
		text_color = Utils.UI_COLORS.PRIMARY_TEXT,
		anchor = {0, 0, 0, 0}, padding = {0, 0, slider_y, 0},
	}))

	demo5:addChild(SliderBar({
		orientation = "horizontal",
		anchor = {0, 0, 0.8, 0}, padding = {0, 0, slider_y + 16, 0}, h = 16,
		max_limit = 400, block_length_percent = 0.05,
		on_value_update = function(val, percent)
			target:setPosition(val, nil)
		end,
	}))
end

return test
