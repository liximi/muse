local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local Scroll = require "ui.widgets.containers.scroll_container"
local CollapsiblePanel = require "ui.widgets.advanced.collapsible_h_screen_edge_panel"
local Tween = require "dependencies.tween"
local UiUtils = require "ui.utils"
local Tooltip = require "ui.widgets.tooltip"
local Checkbox = require "ui.widgets.checkbox"

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
	require "tests.ui.test_image",
	require "tests.ui.test_nineslice",
	require "tests.ui.test_game_settings",
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
	-- 左侧导航面板（可收起）
	--------------------------------------------------
	local sidebar_w = 200
	local left_panel = parent:addChild(CollapsiblePanel({
		w = sidebar_w,
	}))

	left_panel:addChild(Text({
		text = "UI Gallery",
		font_size = 20,
		font_key = "default_bold",
		h = 28,
		text_color = UiUtils.UI_COLORS.TITLE,
		anchor = {0, 0, 1, 0},
		padding = {16, 40, 12, 0}
	}))

	left_panel:addChild(Text({
		text = "Select a component to view",
		font_size = 12,
		h = 16,
		text_color = UiUtils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {16, 40, 42, 0}
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
	scroll:setScrollableH(total_h)

	-- Canvas 缓存开关
	local cache_toggle = left_panel:addChild(Checkbox({
		style = "toggle",
		label = "Canvas cache",
		label_font_size = 11,
		label_color = UiUtils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 1, 1, 1},
		padding = {12, 0, -26, 0},
		h = 22,
		on_checked = function(_self, checked)
			display_area:enableCanvasCache(checked)
			-- 切换时强制刷新缓存
			if checked then
				display_area:invalidateCanvasCache()
			end
		end,
	}))

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

	-- 收起时留 tab_visible 宽度可见，展开按钮保持原位
	local tab_visible = 32  -- 收起后露出面板右侧的宽度（含 24px 按钮 + 边距）
	left_panel.close_x = -(sidebar_w - tab_visible)
	left_panel.collapse_btn_x_close = left_panel.collapse_btn_x

	-- 右侧面板 tween（与侧边栏同步缓动）
	local right_tween = nil

	-- 侧边栏 toggle 时同步启动右侧面板动画
	local orig_toggle = left_panel.toggleOpen
	left_panel.toggleOpen = function(self)
		orig_toggle(self)
		local target = self.open and (sidebar_w + 4) or (tab_visible + 4)
		right_tween = Tween.newFunctionalTween(0.3, {
			pad = {right_panel.transform.left, target, function(val)
				right_panel.transform:setPadding(val, nil, nil, nil)
			end}
		}, "outQuint")
	end

	-- 在侧边栏 onUpdate 中驱动右侧 tween
	local orig_update = left_panel.onUpdate
	left_panel.onUpdate = function(self, dt)
		orig_update(self, dt)
		if right_tween then
			if right_tween:update(dt) then
				right_tween = nil
			end
		end
	end

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

		-- 销毁旧测试场景的所有 widget（释放 GPU 资源）
		display_area:clearChildren()
		Tooltip.destroyAll()

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
