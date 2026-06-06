local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local Scroll = require "ui.widgets.containers.scroll_container"
local UiUtils = require "ui.utils"

-- 加载所有测试模块
local test_modules = {
	require "tests.ui.test_buttons",
	require "tests.ui.test_textinput",
	require "tests.ui.test_checkbox",
	require "tests.ui.test_progressbar",
	require "tests.ui.test_radio",
	require "tests.ui.test_tabview",
	require "tests.ui.test_slider",
	require "tests.ui.test_modal",
	require "tests.ui.test_chat",
	require "tests.ui.test_transform",
	require "tests.ui.test_tooltip",
	require "tests.ui.test_dropdown",
}

--[[
	创建 UI Gallery 浏览器，作为 parent 的子元素添加
	返回 { selectTest = function(index) }
]]
local function Gallery(parent)
	local display_area
	local current_test
	local gallery_btns = {}
	local selectTest -- 前置声明，供按钮闭包捕获

	--------------------------------------------------
	-- 左侧导航面板
	--------------------------------------------------
	local sidebar_w = 200
	local left_panel = parent:addChild(Panel({
		w = sidebar_w,
		anchor = {0, 0, 0, 1},
		padding = {0, nil, 0, 0}
	}))

	left_panel:addChild(Text({
		text = "UI Gallery",
		font_size = 20,
		font_key = "default_bold",
		h = 28,
		text_color = UiUtils.UI_COLORS.TITLE,
		anchor = {0, 0, 1, 0},
		padding = {16, 16, 12, 0}
	}))

	left_panel:addChild(Text({
		text = "Select a component to view",
		font_size = 12,
		h = 16,
		text_color = UiUtils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {16, 16, 42, 0}
	}))

	-- 可滚动的导航按钮列表
	local scroll = left_panel:addChild(Scroll({
		anchor = {0, 0, 1, 1},
		padding = {4, 4, 62, 4},
		enable_scroll_h = false
	}))


	local btn_list = Widget({
		anchor = {0, 0, 1, 0}
	})
	local btn_h = 32
	local btn_space = 4
	local total_h = #test_modules * (btn_h + btn_space)
	btn_list.transform:setSize(nil, total_h)

	for i, mod in ipairs(test_modules) do
		local y_pos = (i - 1) * (btn_h + btn_space)
		local btn = Button({
			anchor = {0, 0, 1, 0},
			padding = {0, 0, y_pos, 0},
			h = btn_h,
			normal = UiUtils.newButtonStateStyle(mod.name),
			on_click = function()
				selectTest(i)
			end
		})
		btn_list:addChild(btn)
		gallery_btns[i] = btn
	end
	scroll:setItem(btn_list)

	--------------------------------------------------
	-- 右侧展示画布
	--------------------------------------------------
	local right_panel = parent:addChild(Panel({
		anchor = {0, 0, 1, 1},
		padding = {sidebar_w + 4, 4, 4, 4}
	}))

	right_panel:addChild(Text({
		text = "Component Preview",
		font_size = 14,
		h = 20,
		text_color = UiUtils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0},
		padding = {12, 12, 12, 0}
	}))

	display_area = right_panel:addChild(Widget({
		anchor = {0, 0, 1, 1},
		padding = {12, 12, 38, 12}
	}))

	-- 切换测试模块
	selectTest = function(index)
		if index == current_test then
			return
		end

		if current_test and gallery_btns[current_test] then
			gallery_btns[current_test]:setSelected(false)
		end
		current_test = index
		gallery_btns[index]:setSelected(true)

		local mod = test_modules[index]
		if mod and mod.create then
			mod.create(display_area)
		end
	end

	return {
		selectTest = selectTest
	}
end

return Gallery
