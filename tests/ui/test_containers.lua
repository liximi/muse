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
local Grid = require "ui.widgets.containers.grid_container"
local Flow = require "ui.widgets.containers.flow_container"
local PanelContainer = require "ui.widgets.containers.panel_container"
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
		local c = m:addChild(Center({}))
		c:addChild(Button({ text = "居中+边距" }))
	end

	-- 5. HBox alignment
	root_vbox:addChild(Text({
		text = "5. HBox alignment=end（无 EXPAND 时整体靠右）",
		font_size = 14,
	}))
	do
		local hbox = root_vbox:addChild(Box({ orientation = ORIENT.HORIZONTAL,  h = 40, separation = 8, alignment = ALIGN.END }))

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
		vbox:addChild(Button({ text = "顶部" }))
		vbox:addChild(Spacer())
		vbox:addChild(Button({ text = "底部" }))
	end

	-- 10. GridContainer — 3 列网格
	root_vbox:addChild(Text({
		text = "10. GridContainer — 3 列网格（columns=3）",
		font_size = 14,
	}))
	do
		local grid = root_vbox:addChild(Grid({ columns = 3, h_separation = 8, v_separation = 8 }))
		for i = 1, 6 do
			grid:addChild(Button({ text = "格 " .. i }))
		end
	end

	-- 11. GridContainer — 不等宽内容
	root_vbox:addChild(Text({
		text = "11. GridContainer — 列宽自动对齐（最长文本决定列宽）",
		font_size = 14,
	}))
	do
		local grid = root_vbox:addChild(Grid({ columns = 2, h_separation = 8, v_separation = 8 }))
		grid:addChild(Button({ text = "短" }))
		grid:addChild(Button({ text = "这个按钮很长很长" }))
		grid:addChild(Button({ text = "中等长度" }))
		grid:addChild(Button({ text = "OK" }))
	end

	-- 12. FlowContainer — 水平流式
	root_vbox:addChild(Text({
		text = "12. FlowContainer — 水平流式换行",
		font_size = 14,
	}))
	do
		local flow = root_vbox:addChild(Flow({ h_separation = 6, v_separation = 6 }))
		local labels = { "标签A", "很长的标签B", "C", "标签D", "另一个标签E", "短", "长长的标签F",
			"G", "较长标签H", "I", "J", "标签K", "L", "超长标签名称M", "N",
			"O", "很长很长很长的标签P", "Q", "R", "S", "标签T", "U",
			"V", "超长的W", "X", "Y", "最终标签Z",
		}
		for _, label in ipairs(labels) do
			flow:addChild(Button({ text = label, h_size_flags = 0, v_size_flags = 0 }))
		end
	end

	-- 13. FlowContainer — 末行对齐
	root_vbox:addChild(Text({
		text = "13. FlowContainer — alignment=center, last_wrap=end（末行靠右）",
		font_size = 14,
	}))
	do
		local flow = root_vbox:addChild(Flow({
			h_separation = 6, v_separation = 6,
			alignment = ALIGN.CENTER,
			last_wrap_alignment = "end",
		}))
		for i = 1, 30 do
			flow:addChild(Button({ text = "项 " .. i, h_size_flags = 0, v_size_flags = 0 }))
		end
	end

	-- 14. PanelContainer — 带面板的容器
	root_vbox:addChild(Text({
		text = "14. PanelContainer — 带背景面板的容器（嵌套 VBox）",
		font_size = 14,
	}))
	do
		local pc = root_vbox:addChild(PanelContainer({
			outline_width = 2,
			outline_color = Utils.UI_COLORS.LINE,
		}))
		local inner = pc:addChild(Box({ auto_size = true, separation = 4 }))
		inner:addChild(Button({ text = "面板内按钮 1" }))
		inner:addChild(Button({ text = "面板内按钮 2" }))
	end

	-- 15. ScrollMode 演示
	root_vbox:addChild(Text({
		text = "15. ScrollMode — SHOW_ALWAYS（始终显示滚动条）vs AUTO（自动隐藏）",
		font_size = 14,
	}))
	do
		local hbox = root_vbox:addChild(Box({ orientation = ORIENT.HORIZONTAL, h = 120, separation = 12 }))

		-- SHOW_ALWAYS — 8 项超出，始终显示滚动条
		local s1 = hbox:addChild(Scroll({
			horizontal_scroll_mode = "disabled",
			vertical_scroll_mode = "show_always",
			h_size_flags = SZ.FILL + SZ.EXPAND,
		}))
		local list1 = Box({ auto_size = true, separation = 4, anchor = {0, 0, 1, 0} })
		s1:setItem(list1)
		for i = 1, 8 do list1:addChild(Button({ text = "项 #" .. i })) end

		-- AUTO — 3 项不溢出，滚动条自动隐藏
		local s2 = hbox:addChild(Scroll({
			horizontal_scroll_mode = "disabled",
			vertical_scroll_mode = "auto",
			h_size_flags = SZ.FILL + SZ.EXPAND,
		}))
		local list2 = Box({ auto_size = true, separation = 4, anchor = {0, 0, 1, 0} })
		s2:setItem(list2)
		for i = 1, 3 do list2:addChild(Button({ text = "项 #" .. i })) end
	end
end

return test
