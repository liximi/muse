--------------------------------------------------
-- 游戏设置示例场景
-- 演示如何使用 Muse 组件构建完整的游戏设置界面
-- 使用 ListVContainer 进行垂直自动布局
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local Checkbox = require "ui.widgets.checkbox"
local Dropdown = require "ui.widgets.dropdown"
local SliderBar = require "ui.widgets.sliderbar"
local TabView = require "ui.widgets.tabview"
local Scroll = require "ui.widgets.containers.scroll_container"
local ListV = require "ui.widgets.containers.list_v_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

--------------------------------------------------
-- 伪常量
--------------------------------------------------
local ROW_H = 40            -- 每行高度（像素）
local ROW_GAP = 4           -- ListV 行间距
local SECTION_H = 26        -- 分区标题高度
local LABEL_W = 160         -- 标签固定宽度
local CONTROL_X = 180       -- 控件左边缘 x（12 margin + 160 label + 8 gap）
local CONTROL_W = 220       -- 控件宽度
local BOTTOM_BAR_H = 44     -- 底部操作栏高度
local TITLE_H = 28          -- 标题高度
local TITLE_BOTTOM = 8      -- 标题底部间距

local test = {}
test.name = "Game Settings"

--------------------------------------------------
-- 辅助函数：创建行容器（水平排列标签 + 控件）
--------------------------------------------------

--- 创建分区标题行
local function makeSectionRow(title_text)
	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = SECTION_H,
	})
	row:addChild(Text({
		text = title_text,
		font_size = 11,
		h = SECTION_H,
		text_color = uc.HINT,
		v_align = "bottom",
		anchor = {0, 0, 1, 0},
		padding = {12, 0, 0, 0},
	}))
	return row
end

--- 创建下拉选择行，返回 { row, dropdown }
local function makeDropdownRow(label_text, options, selected, on_select)
	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = ROW_H,
	})
	row:addChild(Text({
		text = label_text,
		font_size = 13,
		h = ROW_H,
		text_color = uc.PRIMARY_TEXT,
		v_align = "center",
		anchor = {0, 0, 0, 0},
		padding = {12, 0, 0, 0},
		w = LABEL_W,
	}))
	local dd = row:addChild(Dropdown({
		options = options,
		selected_index = selected,
		on_select = on_select,
		w = CONTROL_W,
		h = 28,
		anchor = {0, 0, 0, 0},
		padding = {CONTROL_X, 0, (ROW_H - 28) / 2, 0},
	}))
	return row, dd
end

--- 创建滑块行，返回 { row, slider, value_label }
local function makeSliderRow(label_text, max_limit, value, format_fn, on_release)
	local value_str = format_fn and format_fn(value) or tostring(value)

	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = ROW_H,
	})
	row:addChild(Text({
		text = label_text,
		font_size = 13,
		h = ROW_H,
		text_color = uc.PRIMARY_TEXT,
		v_align = "center",
		anchor = {0, 0, 0, 0},
		padding = {12, 0, 0, 0},
		w = LABEL_W,
	}))
	local slider = row:addChild(SliderBar({
		orientation = "horizontal",
		max_limit = max_limit,
		value = value,
		anchor = {0, 0, 0, 0},
		padding = {CONTROL_X, 0, (ROW_H - 14) / 2, 0},
		w = CONTROL_W,
		h = 14,
		block_length_percent = 0.1,
		block_min_len = 15,
	}))
	local value_label = row:addChild(Text({
		text = value_str,
		font_size = 12,
		h = ROW_H,
		text_color = uc.SECONDARY_TEXT,
		h_align = "right",
		v_align = "center",
		anchor = {0, 0, 0, 0},
		padding = {CONTROL_X + CONTROL_W + 8, 0, 0, 0},
		w = 52,
	}))

	-- 拖动时只更新数值标签，不触发业务回调
	slider:setOnValueUpdateFn(function(val, pct)
		local display = format_fn and format_fn(val) or tostring(val)
		value_label:setText(display)
	end)

	-- 鼠标松开时（仅当之前正在拖拽）触发回调
	if on_release then
		local orig_click = slider.block.onClick
		slider.block.onClick = function(_self)
			if slider.drag then
				on_release(slider.value, slider.value / slider.max_limit)
			end
			if orig_click then orig_click(_self) end
		end
	end

	return row, slider, value_label
end

--- 创建开关行，返回 { row, checkbox }
local function makeToggleRow(label_text, checked, on_checked)
	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = ROW_H,
	})
	row:addChild(Text({
		text = label_text,
		font_size = 13,
		h = ROW_H,
		text_color = uc.PRIMARY_TEXT,
		v_align = "center",
		anchor = {0, 0, 0, 0},
		padding = {12, 0, 0, 0},
		w = LABEL_W,
	}))
	local cb = row:addChild(Checkbox({
		style = "toggle",
		checked = checked,
		on_checked = on_checked,
		anchor = {0, 0, 0, 0},
		padding = {CONTROL_X, 0, (ROW_H - 20) / 2, 0},
		w = 44,
		h = 20,
	}))
	return row, cb
end

--------------------------------------------------
-- 创建主函数
--------------------------------------------------
function test.create(parent)
	parent:removeAllChildren()
	Dropdown.destroyAll()

	--------------------------------------------------
	-- 读取当前 LÖVE 窗口设置
	--------------------------------------------------
	local cur_w, cur_h, cur_flags = love.window.getMode()
	local cur_vsync = love.window.getVSync() > 0
	local cur_msaa = cur_flags.msaa or 0

	-- 分辨率选项：从系统支持的全屏模式列表中获取，去重排序
	local fullscreen_modes = love.window.getFullscreenModes()
	-- 返回格式: {{width=2560, height=1440}, ...}（已验证）
	local res_options = {}  -- { {w, h, label}, ... }
	local res_strings = {}  -- 扁平字符串列表，供 Dropdown 使用
	local res_selected = 1
	local seen_res = {}
	for _, mode in ipairs(fullscreen_modes) do
		local mw, mh = mode.width, mode.height
		if mw and mh then
			local key = mw .. "×" .. mh
			if not seen_res[key] then
				seen_res[key] = true
				table.insert(res_options, {w = mw, h = mh, label = key})
			end
		end
	end
	table.sort(res_options, function(a, b)
		if a.w ~= b.w then return a.w > b.w end
		return a.h > b.h
	end)
	local cur_key = cur_w .. "×" .. cur_h
	for i, r in ipairs(res_options) do
		table.insert(res_strings, r.label)
		if r.label == cur_key then res_selected = i end
	end
	-- 如果当前分辨率不在系统列表中（窗口模式自定义尺寸），追加
	if not seen_res[cur_key] then
		table.insert(res_options, {w = cur_w, h = cur_h, label = cur_key})
		table.insert(res_strings, cur_key)
		res_selected = #res_strings
	end

	-- 显示模式：从当前 flags 推导选中索引
	local display_mode_idx
	if cur_flags.fullscreen then
		display_mode_idx = 1
	elseif cur_flags.borderless then
		display_mode_idx = 2
	else
		display_mode_idx = 3
	end

	-- MSAA 选项（对应 love.window.setMode 的 msaa 参数）
	local msaa_options = {"关闭", "2x MSAA", "4x MSAA", "8x MSAA"}
	local msaa_values = {0, 2, 4, 8}
	local msaa_idx = 1
	for i, v in ipairs(msaa_values) do
		if v == cur_msaa then msaa_idx = i; break end
	end

	-- 应用窗口模式：收集当前设置状态，调用 love.window.setMode
	local function applyWindowMode()
		local r = res_options[res_selected]
		if not r then
			print(string.format("[Window] Invalid resolution index: %d (total %d items)", res_selected, #res_options))
			return
		end
		local flags = {
			fullscreen = (display_mode_idx == 1),
			fullscreentype = (display_mode_idx == 1) and "exclusive" or "desktop",
			borderless = (display_mode_idx == 2),
			vsync = cur_vsync,
			msaa = msaa_values[msaa_idx],
			resizable = true,
			centered = true,
		}
		local ok = love.window.setMode(r.w, r.h, flags)
		if ok then
			print(string.format("[Window] %dx%d fullscreen=%s borderless=%s vsync=%s msaa=%d",
				r.w, r.h, tostring(flags.fullscreen), tostring(flags.borderless),
				tostring(flags.vsync), flags.msaa))
		else
			print("[Window] setMode failed")
		end
	end

	--------------------------------------------------
	-- 存储所有设置控件的引用（用于 Apply / Reset）
	--------------------------------------------------
	local setting_widgets = {}

	--------------------------------------------------
	-- 标题
	--------------------------------------------------
	parent:addChild(Text({
		text = "游戏设置",
		font_size = 18,
		font_key = "default_bold",
		h = TITLE_H,
		text_color = uc.TITLE,
		anchor = {0, 0, 1, 0},
		padding = {12, 0, 0, 0},
	}))

	--------------------------------------------------
	-- 画面 Tab
	--------------------------------------------------
	local tab_graphics = Widget({ anchor = {0, 0, 1, 1} })
	local scroll_gfx = tab_graphics:addChild(Scroll({
		anchor = {0, 0, 1, 1},
		padding = {0, 4, 0, 0},
		enable_scroll_h = false,
		v_bar_pad_top = 8,
		v_bar_pad_bottom = 8,
	}))

	local gfx_items = {}
	local row, dd, cb, slider, vlbl

	-- 显示
	table.insert(gfx_items, makeSectionRow("显示"))

	row, dd = makeDropdownRow("分辨率", res_strings, res_selected,
		function(_self, idx, val)
			res_selected = idx
			applyWindowMode()
		end)
	table.insert(gfx_items, row)
	setting_widgets.resolution = { widget = dd, type = "dropdown", default_idx = res_selected }

	row, dd = makeDropdownRow("显示模式",
		{"全屏", "无边框窗口", "窗口"}, display_mode_idx,
		function(_self, idx, val)
			display_mode_idx = idx
			applyWindowMode()
		end)
	table.insert(gfx_items, row)
	setting_widgets.display_mode = { widget = dd, type = "dropdown", default_idx = display_mode_idx }

	row, cb = makeToggleRow("垂直同步", cur_vsync,
		function(_self, checked)
			cur_vsync = checked
			applyWindowMode()
		end)
	table.insert(gfx_items, row)
	setting_widgets.vsync = { widget = cb, type = "toggle", default = cur_vsync }

	-- 画质
	table.insert(gfx_items, makeSectionRow("画质"))

	row, dd = makeDropdownRow("画质预设",
		{"极高", "高", "中", "低"}, 2,
		function(_self, idx, val) print("[Settings] Quality preset ->", val) end)
	table.insert(gfx_items, row)
	setting_widgets.quality = { widget = dd, type = "dropdown", default_idx = 2 }

	row, slider, vlbl = makeSliderRow("亮度", 100, 80,
		function(val) return string.format("%d%%", val) end,
		function(val) print("[Settings] Brightness ->", val) end)
	table.insert(gfx_items, row)
	setting_widgets.brightness = { widget = slider, type = "slider", default = 80 }

	row, slider, vlbl = makeSliderRow("视野 (FOV)", 120, 90,
		function(val) return string.format("%d", val) end,
		function(val) print("[Settings] FOV ->", val) end)
	table.insert(gfx_items, row)
	setting_widgets.fov = { widget = slider, type = "slider", default = 90 }

	row, dd = makeDropdownRow("抗锯齿", msaa_options, msaa_idx,
		function(_self, idx, val)
			msaa_idx = idx
			applyWindowMode()
		end)
	table.insert(gfx_items, row)
	setting_widgets.antialiasing = { widget = dd, type = "dropdown", default_idx = msaa_idx }

	row, dd = makeDropdownRow("纹理质量",
		{"极高", "高", "中", "低"}, 2,
		function(_self, idx, val) print("[Settings] Texture quality ->", val) end)
	table.insert(gfx_items, row)
	setting_widgets.texture_quality = { widget = dd, type = "dropdown", default_idx = 2 }

	local gfx_list = ListV({
		anchor = {0, 0, 1, 0},
		space = ROW_GAP,
		items = gfx_items,
	})
	scroll_gfx:setItem(gfx_list)
	scroll_gfx:setScrollableH(gfx_list.transform.h)

	--------------------------------------------------
	-- 音频 Tab
	--------------------------------------------------
	local tab_audio = Widget({ anchor = {0, 0, 1, 1} })
	local scroll_aud = tab_audio:addChild(Scroll({
		anchor = {0, 0, 1, 1},
		padding = {0, 4, 0, 0},
		enable_scroll_h = false,
		v_bar_pad_top = 8,
		v_bar_pad_bottom = 8,
	}))

	local aud_items = {}

	row, slider, vlbl = makeSliderRow("主音量", 100, 80,
		function(val) return string.format("%d%%", val) end,
		function(val) print("[Settings] Master volume ->", val) end)
	table.insert(aud_items, row)
	setting_widgets.master_volume = { widget = slider, type = "slider", default = 80 }

	row, slider, vlbl = makeSliderRow("音乐音量", 100, 75,
		function(val) return string.format("%d%%", val) end,
		function(val) print("[Settings] Music volume ->", val) end)
	table.insert(aud_items, row)
	setting_widgets.music_volume = { widget = slider, type = "slider", default = 75 }

	row, slider, vlbl = makeSliderRow("音效音量", 100, 90,
		function(val) return string.format("%d%%", val) end,
		function(val) print("[Settings] SFX volume ->", val) end)
	table.insert(aud_items, row)
	setting_widgets.sfx_volume = { widget = slider, type = "slider", default = 90 }

	row, slider, vlbl = makeSliderRow("语音音量", 100, 85,
		function(val) return string.format("%d%%", val) end,
		function(val) print("[Settings] Voice volume ->", val) end)
	table.insert(aud_items, row)
	setting_widgets.voice_volume = { widget = slider, type = "slider", default = 85 }

	row, slider, vlbl = makeSliderRow("环境音量", 100, 60,
		function(val) return string.format("%d%%", val) end,
		function(val) print("[Settings] Ambient volume ->", val) end)
	table.insert(aud_items, row)
	setting_widgets.ambient_volume = { widget = slider, type = "slider", default = 60 }

	row, cb = makeToggleRow("后台静音", false,
		function(_self, checked) print("[Settings] Mute in bg ->", checked) end)
	table.insert(aud_items, row)
	setting_widgets.mute_in_bg = { widget = cb, type = "toggle", default = false }

	local aud_list = ListV({
		anchor = {0, 0, 1, 0},
		space = ROW_GAP,
		items = aud_items,
	})
	scroll_aud:setItem(aud_list)
	scroll_aud:setScrollableH(aud_list.transform.h)

	--------------------------------------------------
	-- 游戏 Tab
	--------------------------------------------------
	local tab_gameplay = Widget({ anchor = {0, 0, 1, 1} })
	local scroll_gp = tab_gameplay:addChild(Scroll({
		anchor = {0, 0, 1, 1},
		padding = {0, 4, 0, 0},
		enable_scroll_h = false,
		v_bar_pad_top = 8,
		v_bar_pad_bottom = 8,
	}))

	local gp_items = {}

	-- 通用
	table.insert(gp_items, makeSectionRow("通用"))

	row, dd = makeDropdownRow("游戏难度",
		{"简单", "普通", "困难", "噩梦"}, 2,
		function(_self, idx, val) print("[Settings] Difficulty ->", val) end)
	table.insert(gp_items, row)
	setting_widgets.difficulty = { widget = dd, type = "dropdown", default_idx = 2 }

	row, dd = makeDropdownRow("语言",
		{"简体中文", "English", "日本語", "한국어"}, 1,
		function(_self, idx, val) print("[Settings] Language ->", val) end)
	table.insert(gp_items, row)
	setting_widgets.language = { widget = dd, type = "dropdown", default_idx = 1 }

	row, dd = makeDropdownRow("自动保存",
		{"关闭", "每 5 分钟", "每 10 分钟", "每 30 分钟"}, 3,
		function(_self, idx, val) print("[Settings] Autosave ->", val) end)
	table.insert(gp_items, row)
	setting_widgets.autosave = { widget = dd, type = "dropdown", default_idx = 3 }

	-- 操控
	table.insert(gp_items, makeSectionRow("操控"))

	row, slider, vlbl = makeSliderRow("鼠标灵敏度", 100, 50,
		function(val) return string.format("%d%%", val) end,
		function(val) print("[Settings] Mouse sensitivity ->", val) end)
	table.insert(gp_items, row)
	setting_widgets.mouse_sensitivity = { widget = slider, type = "slider", default = 50 }

	row, cb = makeToggleRow("Y 轴反转", false,
		function(_self, checked) print("[Settings] Invert Y ->", checked) end)
	table.insert(gp_items, row)
	setting_widgets.invert_y = { widget = cb, type = "toggle", default = false }

	row, cb = makeToggleRow("手柄震动", true,
		function(_self, checked) print("[Settings] Vibration ->", checked) end)
	table.insert(gp_items, row)
	setting_widgets.vibration = { widget = cb, type = "toggle", default = true }

	row, cb = makeToggleRow("显示准星", true,
		function(_self, checked) print("[Settings] Crosshair ->", checked) end)
	table.insert(gp_items, row)
	setting_widgets.crosshair = { widget = cb, type = "toggle", default = true }

	local gp_list = ListV({
		anchor = {0, 0, 1, 0},
		space = ROW_GAP,
		items = gp_items,
	})
	scroll_gp:setItem(gp_list)
	scroll_gp:setScrollableH(gp_list.transform.h)

	--------------------------------------------------
	-- 辅助功能 Tab
	--------------------------------------------------
	local tab_accessibility = Widget({ anchor = {0, 0, 1, 1} })
	local scroll_acc = tab_accessibility:addChild(Scroll({
		anchor = {0, 0, 1, 1},
		padding = {0, 4, 0, 0},
		enable_scroll_h = false,
		v_bar_pad_top = 8,
		v_bar_pad_bottom = 8,
	}))

	local acc_items = {}

	row, dd = makeDropdownRow("色盲模式",
		{"关闭", "红色盲", "绿色盲", "蓝黄色盲"}, 1,
		function(_self, idx, val) print("[Settings] Colorblind mode ->", val) end)
	table.insert(acc_items, row)
	setting_widgets.colorblind = { widget = dd, type = "dropdown", default_idx = 1 }

	row, dd = makeDropdownRow("字幕大小",
		{"小", "中", "大", "特大"}, 2,
		function(_self, idx, val) print("[Settings] Subtitle size ->", val) end)
	table.insert(acc_items, row)
	setting_widgets.subtitle_size = { widget = dd, type = "dropdown", default_idx = 2 }

	row, cb = makeToggleRow("字幕背景", true,
		function(_self, checked) print("[Settings] Subtitle bg ->", checked) end)
	table.insert(acc_items, row)
	setting_widgets.subtitle_bg = { widget = cb, type = "toggle", default = true }

	row, cb = makeToggleRow("屏幕震动", true,
		function(_self, checked) print("[Settings] Screen shake ->", checked) end)
	table.insert(acc_items, row)
	setting_widgets.screen_shake = { widget = cb, type = "toggle", default = true }

	row, cb = makeToggleRow("减弱动效", false,
		function(_self, checked) print("[Settings] Reduce motion ->", checked) end)
	table.insert(acc_items, row)
	setting_widgets.reduce_motion = { widget = cb, type = "toggle", default = false }

	row, slider, vlbl = makeSliderRow("UI 缩放", 150, 100,
		function(val) return string.format("%d%%", val) end,
		function(val) print("[Settings] UI scale ->", val) end)
	table.insert(acc_items, row)
	setting_widgets.ui_scale = { widget = slider, type = "slider", default = 100 }

	local acc_list = ListV({
		anchor = {0, 0, 1, 0},
		space = ROW_GAP,
		items = acc_items,
	})
	scroll_acc:setItem(acc_list)
	scroll_acc:setScrollableH(acc_list.transform.h)

	--------------------------------------------------
	-- TabView
	--------------------------------------------------
	parent:addChild(TabView({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, TITLE_H + TITLE_BOTTOM, BOTTOM_BAR_H},
		tabs = {
			{label = "画面",     content = tab_graphics},
			{label = "音频",     content = tab_audio},
			{label = "游戏",     content = tab_gameplay},
			{label = "辅助功能", content = tab_accessibility},
		},
		on_tab_changed = function(idx)
			print("[Settings] Tab switched to:", idx)
		end,
	}))

	--------------------------------------------------
	-- 收集当前设置值并打印
	--------------------------------------------------
	local function collectSettings()
		print("========== Current Game Settings ==========")
		for key, entry in pairs(setting_widgets) do
			local w = entry.widget
			if entry.type == "dropdown" then
				local idx = w:getSelectedIndex()
				local val = w:getSelectedValue()
				print(string.format("  %s = %s (index=%d)", key, val, idx))
			elseif entry.type == "slider" then
				print(string.format("  %s = %s", key, tostring(w.value)))
			elseif entry.type == "toggle" then
				print(string.format("  %s = %s", key, tostring(w:isChecked())))
			end
		end
		print("============================================")
	end

	--- 恢复所有设置为默认值
	local function resetAll()
		print("[Settings] Reset to defaults")
		for key, entry in pairs(setting_widgets) do
			local w = entry.widget
			if entry.type == "dropdown" then
				w:select(entry.default_idx)
			elseif entry.type == "slider" then
				w:setValue(entry.default)
			elseif entry.type == "toggle" then
				w:setChecked(entry.default)
			end
		end
	end

	--------------------------------------------------
	-- 底部操作栏
	--------------------------------------------------
	local bottom_bar = parent:addChild(Panel({
		bg_color = {0.08, 0.08, 0.10, 0.95},
		outline_width = 1,
		outline_color = Utils.RGB(50, 50, 55),
		rounding_radius = 0,
		anchor = {0, 1, 1, 1},
		padding = {0, 0, -BOTTOM_BAR_H, 0},
		h = BOTTOM_BAR_H,
	}))

	-- 恢复默认按钮（靠左）
	bottom_bar:addChild(Button({
		normal = Utils.newButtonStateStyle("恢复默认", uc.SECONDARY_TEXT, 12,
			{0, 0, 0, 0}, 0, nil, nil, nil, 0),
		hover = Utils.newButtonStateStyle(nil, uc.PRIMARY_TEXT, nil,
			uc.BTN_HOVER, 0, nil, nil, nil, 4),
		pressed = Utils.newButtonStateStyle(nil, nil, nil, nil, nil, nil, {0, 1}),
		anchor = {0, 0, 0, 0},
		padding = {12, 0, 8, 0},
		w = 90,
		h = 28,
		on_click = function()
			resetAll()
		end,
	}))

	-- 取消按钮（靠右，pivot={1,0} + 负 left 偏移）
	bottom_bar:addChild(Button({
		normal = Utils.newButtonStateStyle("取消", uc.PRIMARY_TEXT, 12,
			uc.BTN_NORMAL, 1, Utils.RGB(70, 70, 75), nil, nil, 4),
		hover = Utils.newButtonStateStyle(nil, nil, nil,
			uc.BTN_HOVER, 1, uc.LINE, nil, nil, 4),
		pressed = Utils.newButtonStateStyle(nil, nil, nil, nil, nil, nil, {0, 1}),
		anchor = {1, 0, 1, 0},
		pivot = {1, 0},
		padding = {-160, 0, 8, 0},
		w = 72,
		h = 28,
		on_click = function()
			print("[Settings] Cancel - current values:")
			collectSettings()
		end,
	}))

	-- 应用按钮（靠右，pivot={1,0} + 负 left 偏移）
	bottom_bar:addChild(Button({
		normal = Utils.newButtonStateStyle("应用", uc.TITLE, 12,
			uc.ACCENT, 0, nil, nil, nil, 4),
		hover = Utils.newButtonStateStyle(nil, nil, nil,
			uc.ACCENT_LIGHT, 0, nil, nil, nil, 4),
		pressed = Utils.newButtonStateStyle(nil, nil, nil, nil, nil, nil, {0, 1}),
		anchor = {1, 0, 1, 0},
		pivot = {1, 0},
		padding = {-84, 0, 8, 0},
		w = 72,
		h = 28,
		on_click = function()
			print("[Settings] Apply - saving settings:")
			collectSettings()
		end,
	}))
end

return test
