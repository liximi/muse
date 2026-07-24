--------------------------------------------------
-- 容器系统测试场景
-- 粉色框 = 容器边界，内部元素不画框
--------------------------------------------------

local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local Box = require "ui.widgets.containers.box_container"
local Margin = require "ui.widgets.containers.margin_container"
local Center = require "ui.widgets.containers.center_container"
local Scroll = require "ui.widgets.containers.scroll_container"
local Spacer = require "ui.widgets.spacer"
local Utils = require "ui.utils"
local ORIENT = Utils.ORIENTATION
local ALIGN = Utils.ALIGNMENT

local SZ = Utils.SIZE_FLAGS

local test = {}
test.name = "Containers"

function test.create(parent)
	parent:removeAllChildren()

	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
	}))

	-- 根布局：Margin → Scroll → VBox
	local root_vbox = Box({ auto_size = true, separation = 12, anchor = {0, 0, 1, 0} })
	local margin = parent:addChild(Margin({
		anchor = {0, 0, 1, 1},
		margin_left = 12, margin_right = 12,
		margin_top = 12, margin_bottom = 12,
	}))
	local scroll = margin:addChild(Scroll({
		anchor = {0, 0, 1, 1},
	}))
	scroll:setItem(root_vbox)
	margin:enableDebug(true)
	scroll:enableDebug(true)

	root_vbox:addChild(Text({
		text = "容器系统测试  |  粉色框 = 容器边界",
		font_size = 18,
	}))

	-- 1. HBox 等分
	root_vbox:addChild(Text({
		text = "1. HBox — 三个按钮默认 FILL（等分）",
		font_size = 14,
	}))
	do
		local hbox = root_vbox:addChild(Box({ orientation = ORIENT.HORIZONTAL,  h = 40, separation = 8 }))
		hbox:enableDebug(true)
		hbox:addChild(Button({ text = "Button A" }))
		hbox:addChild(Button({ text = "Button B" }))
		hbox:addChild(Button({ text = "Button C" }))
	end

	-- 2. HBox + stretch_ratio
	root_vbox:addChild(Text({
		text = "2. HBox — SHRINK(固定) + EXPAND ratio=2 + EXPAND ratio=1",
		font_size = 14,
	}))
	do
		local hbox = root_vbox:addChild(Box({ orientation = ORIENT.HORIZONTAL,  h = 40, separation = 8 }))
		hbox:enableDebug(true)

		local b1 = hbox:addChild(Button({ text = "固定", h_size_flags = 0 }))

		local b2 = hbox:addChild(Button({ text = "占2/3", h_size_flags = SZ.FILL + SZ.EXPAND, stretch_ratio = 2 }))

		local b3 = hbox:addChild(Button({ text = "占1/3", h_size_flags = SZ.FILL + SZ.EXPAND, stretch_ratio = 1 }))
	end

	-- 3. VBox + SHRINK_CENTER
	root_vbox:addChild(Text({
		text = "3. VBox — SHRINK_CENTER（保持最小尺寸，水平居中）",
		font_size = 14,
	}))
	do
		local vbox = root_vbox:addChild(Box({ h = 120, separation = 4, alignment = ALIGN.CENTER }))
		vbox:enableDebug(true)
		for i = 1, 3 do
			vbox:addChild(Button({ text = "居中 " .. i, h_size_flags = SZ.SHRINK_CENTER, v_size_flags = 0 }))
		end
	end

	-- 4. Margin + Center 嵌套
	root_vbox:addChild(Text({
		text = "4. Margin → Center → Button（边距 + 居中嵌套）",
		font_size = 14,
	}))
	do
		local m = root_vbox:addChild(Margin({
			margin_top = 8, margin_bottom = 8,
			margin_left = 24, margin_right = 24,
			h = 60,
		}))
		m:enableDebug(true)
		local c = m:addChild(Center({}))
		c:enableDebug(true)
		c:addChild(Button({ text = "居中+边距" }))
	end

	-- 5. HBox alignment
	root_vbox:addChild(Text({
		text = "5. HBox alignment=end（无 EXPAND 时整体靠右）",
		font_size = 14,
	}))
	do
		local hbox = root_vbox:addChild(Box({ orientation = ORIENT.HORIZONTAL,  h = 40, separation = 8, alignment = ALIGN.END }))
		hbox:enableDebug(true)

		local b1 = hbox:addChild(Button({ text = "靠", h_size_flags = 0 }))
		local b2 = hbox:addChild(Button({ text = "右", h_size_flags = 0 }))
		local b3 = hbox:addChild(Button({ text = "!", h_size_flags = 0 }))
	end

	-- 6. auto_size
	root_vbox:addChild(Text({
		text = "6. VBox auto_size=true — 高度自动跟随子控件",
		font_size = 14,
	}))
	do
		local vbox = root_vbox:addChild(Box({ auto_size = true, separation = 4 }))
		vbox:enableDebug(true)
		vbox:addChild(Button({ text = "第一行" }))
		vbox:addChild(Button({ text = "第二行" }))
		vbox:addChild(Button({ text = "第三行 —— VBox 高度自动收缩" }))
	end

	-- 7. Scroll + VBox auto_size
	root_vbox:addChild(Text({
		text = "7. Scroll + VBox auto_size（自动追踪，无需手动 setScrollableH）",
		font_size = 14,
	}))
	do
		local scroll = root_vbox:addChild(Scroll({ h = 120 }))
		scroll:enableDebug(true)

		local list = Box({ auto_size = true, separation = 4, anchor = {0, 0, 1, 0} })
		scroll:setItem(list)
		for i = 1, 10 do
			list:addChild(Button({ text = "滚动项 #" .. i }))
		end
	end

	-- 8. Spacer — 把按钮推到右边
	root_vbox:addChild(Text({
		text = "8. Spacer — 占位符把后面的按钮推到右边",
		font_size = 14,
	}))
	do
		local hbox = root_vbox:addChild(Box({ orientation = ORIENT.HORIZONTAL,  h = 40, separation = 8 }))
		hbox:enableDebug(true)
		hbox:addChild(Button({ text = "左侧" }))
		hbox:addChild(Spacer())
		hbox:addChild(Button({ text = "右侧" }))
	end

	-- 9. Spacer — 把按钮推到底部
	root_vbox:addChild(Text({
		text = "9. Spacer — 占位符把后面的按钮推到底部",
		font_size = 14,
	}))
	do
		local vbox = root_vbox:addChild(Box({ h = 100, separation = 4 }))
		vbox:enableDebug(true)
		vbox:addChild(Button({ text = "顶部" }))
		vbox:addChild(Spacer())
		vbox:addChild(Button({ text = "底部" }))
	end
end

return test
