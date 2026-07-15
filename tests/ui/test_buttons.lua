--------------------------------------------------
-- Button / ImageButton 测试场景 — 使用容器布局
--------------------------------------------------

local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local ImageButton = require "ui.widgets.imagebutton"
local Box = require "ui.widgets.containers.box_container"
local Margin = require "ui.widgets.containers.margin_container"
local Utils = require "ui.utils"

local ORIENT = Utils.ORIENTATION
local ALIGN = Utils.ALIGNMENT
local uc = Utils.UI_COLORS

local test = {}
test.name = "Button / ImageButton"

function test.create(parent)
	parent:removeAllChildren()

	-- 背景
	parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
	}))

	local margin = parent:addChild(Margin({
		anchor = {0, 0, 1, 1},
		margin_left = 20, margin_right = 20,
		margin_top = 16, margin_bottom = 16,
	}))

	local root = margin:addChild(Box({ separation = 14 }))

	-- 辅助：创建带标签的 section
	local function section(title)
		local box = Box({ separation = 6 })
		box:addChild(Text({
			text = title,
			font_size = 12,
			text_color = uc.HINT,
		}))
		return box
	end

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	root:addChild(Text({
		text = "Button / ImageButton — 6 种状态 + 选中切换",
		font_size = 18,
	}))

	--------------------------------------------------
	-- 1. 四种预设状态
	--------------------------------------------------
	local sec1 = section("四种预设状态")
	local row1 = sec1:addChild(Box({ orientation = ORIENT.HORIZONTAL, h = 36, separation = 12 }))

	row1:addChild(Button({
		text = "Normal",
		on_click = function() print("Normal clicked") end,
	}))

	local btn_hover = row1:addChild(Button({
		text = "Hover",
		hover = Utils.newButtonStateStyle(nil, nil, nil, uc.BTN_HOVER, nil, nil, {0, -1}),
	}))
	btn_hover:setState(Utils.BTN_STATES.HOVER)

	local btn_selected = row1:addChild(Button({
		text = "Selected",
		selected = Utils.newButtonStateStyle(nil, uc.TITLE, nil, uc.BTN_SELECTED, 1, uc.ACCENT),
		selected_hover = Utils.newButtonStateStyle(nil, nil, nil, uc.BTN_SELECTED_HOVER, 1, uc.ACCENT_LIGHT),
	}))
	btn_selected:setState(Utils.BTN_STATES.SELECTED)

	local btn_disabled = row1:addChild(Button({
		text = "Disabled",
		normal = Utils.newButtonStateStyle("Disabled", uc.SECONDARY_TEXT, nil, uc.BTN_DISABLED, nil, nil, nil, nil, 4),
	}))
	btn_disabled:disable()

	root:addChild(sec1)

	--------------------------------------------------
	-- 2. 切换按钮 (Toggle)
	--------------------------------------------------
	local sec2 = section("切换按钮 (Toggle) — 点击切换选中状态")
	local row2 = sec2:addChild(Box({ orientation = ORIENT.HORIZONTAL, h = 36, separation = 12 }))

	local toggle_btn = row2:addChild(Button({
		text = "Toggle: OFF",
		selected = Utils.newButtonStateStyle("Toggle: ON", uc.TITLE, nil, uc.BTN_SELECTED, 1, uc.ACCENT),
		selected_hover = Utils.newButtonStateStyle("Toggle: ON", uc.TITLE, nil, uc.BTN_SELECTED_HOVER, 1, uc.ACCENT_LIGHT),
		on_click = function(_self)
			local is_sel = _self.cur_state == Utils.BTN_STATES.SELECTED or _self.cur_state == Utils.BTN_STATES.SELECTED_HOVER
			_self:setSelected(not is_sel)
		end,
	}))

	root:addChild(sec2)

	--------------------------------------------------
	-- 3. 事件回调
	--------------------------------------------------
	local sec3 = section("事件回调")
	local row3 = sec3:addChild(Box({ orientation = ORIENT.HORIZONTAL, h = 36, separation = 12 }))

	row3:addChild(Button({
		text = "onClick → print",
		on_click = function() print("Button onClick fired!") end,
	}))

	row3:addChild(Button({
		text = "onPressed → print",
		on_pressed = function() print("Button onPressed fired!") end,
	}))

	root:addChild(sec3)

	--------------------------------------------------
	-- 4. ImageButton
	--------------------------------------------------
	local sec4 = section("ImageButton — 纯图标按钮")
	local row4 = sec4:addChild(Box({ orientation = ORIENT.HORIZONTAL, h = 80, separation = 16, alignment = ALIGN.BEGIN }))

	-- 加载示例图片（如不可用则跳过）
	local tex_path = "assets/example_image_128x128.png"
	local tex = love.filesystem.getInfo(tex_path) and love.graphics.newImage(tex_path)
	if tex then
		row4:addChild(ImageButton({
			h = 48,
			normal = Utils.newImageButtonStateStyle(tex, nil, "Icon A"),
			on_click = function() print("ImageButton A clicked") end,
		}))

		row4:addChild(ImageButton({
			h = 48,
			normal = Utils.newImageButtonStateStyle(tex, {1, 0.7, 0.5}, "Icon B"),
			on_click = function() print("ImageButton B clicked") end,
		}))
	else
		row4:addChild(Text({
			text = "(示例图片不可用)",
			font_size = 12,
			text_color = uc.HINT,
		}))
	end

	root:addChild(sec4)
end

return test
