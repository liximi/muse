--------------------------------------------------
-- inspector/rows.lua — 属性行工厂函数
-- 提供：文本行、颜色行、Dropdown行、Checkbox行、分区标题
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local TextInput = require "ui.widgets.textinput"
local Button = require "ui.widgets.button"
local Dropdown = require "ui.widgets.dropdown"
local CheckboxWidget = require "ui.widgets.checkbox"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local ROW_H = 28
local LABEL_W = 64
local INPUT_W = 122
local INPUT2_W = 56

-- 文本域常量
local TEXTAREA_DEFAULT_H = 56
local TEXTAREA_MIN_H = 32
local TEXTAREA_MAX_H = 200
local GRIP_H = 6
local TEXTAREA_LABEL_H = 16
local TEXTAREA_MARGIN = 20  -- 底部拖拽容差

--------------------------------------------------
-- 将数字四舍五入到 2 位小数显示
local function fmt(n)
	if n == nil then return "" end
	if type(n) == "number" then
		if n == math.floor(n) then return tostring(n) end
		return string.format("%.2f", n)
	end
	return tostring(n)
end

-- 校验：是否为合法数字
local function isValidNumber(s)
	if s == nil or s == "" then return false end
	return tonumber(s) ~= nil
end

-- 为输入框创建统一背景
local function makeInputBg()
	return Panel({
		bg_color = {uc.BG[1], uc.BG[2], uc.BG[3], 0.6},
		outline_width = 1,
		outline_color = uc.LINE,
		rounding_radius = 4,
	})
end

--------------------------------------------------
-- 导出：公用工具函数
--------------------------------------------------
local Rows = {}
Rows.fmt = fmt
Rows.isValidNumber = isValidNumber
Rows.ROW_H = ROW_H
Rows.LABEL_W = LABEL_W
Rows.INPUT_W = INPUT_W
Rows.INPUT2_W = INPUT2_W

--------------------------------------------------
-- 分区标题
--------------------------------------------------
function Rows.makeSectionHeader(text)
	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = 22,
	})
	row:setCustomMinimumSize(nil, 22)
	row:addChild(Text({
		text = text,
		font_size = 10,
		font_key = "default_bold",
		text_color = {uc.HINT[1], uc.HINT[2], uc.HINT[3], 0.7},
		v_align = "center",
		anchor = {0, 0, 1, 0},
		h = 22,
		padding = {12, 0, 0, 0},
	}))
	return row
end

--------------------------------------------------
-- 文本输入行（通用：数字 & 字符串）
--------------------------------------------------
function Rows.makeTextRow(label_text, value_str, on_change, numeric)
	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = ROW_H,
	})
	row:setCustomMinimumSize(nil, ROW_H)

	row:addChild(Text({
		text = label_text,
		font_size = 11,
		text_color = uc.SECONDARY_TEXT,
		v_align = "center",
		anchor = {0, 0, 0, 0},
		w = LABEL_W,
		h = ROW_H,
		padding = {12, 0, 0, 0},
	}))

	local input
	input = row:addChild(TextInput({
		text = value_str,
		font_size = 11,
		text_color = uc.PRIMARY_TEXT,
		single_line = true,
		v_align = "center",
		bg = makeInputBg(),
		anchor = {0, 0, 0, 0},
		w = INPUT_W,
		h = 22,
		padding = {LABEL_W + 12, 0, (ROW_H - 22) / 2, 0},
		on_submit = function()
			local text = input:getText()
			if on_change then
				if numeric then
					if isValidNumber(text) then
						on_change(text)
					end
				else
					on_change(text)
				end
			end
		end,
	}))

	return row, input
end

--------------------------------------------------
-- 双输入行（如锚点 min / max）
--------------------------------------------------
function Rows.makeRow2(label_text, val1_str, val2_str, on_change1, on_change2)
	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = ROW_H,
	})
	row:setCustomMinimumSize(nil, ROW_H)

	row:addChild(Text({
		text = label_text,
		font_size = 11,
		text_color = uc.SECONDARY_TEXT,
		v_align = "center",
		anchor = {0, 0, 0, 0},
		w = LABEL_W,
		h = ROW_H,
		padding = {12, 0, 0, 0},
	}))

	local input_w = INPUT2_W
	local gap = 4
	local x1 = LABEL_W + 12
	local x2 = x1 + input_w + gap
	local y_off = (ROW_H - 22) / 2

	local input1
	input1 = row:addChild(TextInput({
		text = val1_str,
		font_size = 11,
		text_color = uc.PRIMARY_TEXT,
		single_line = true,
		v_align = "center",
		bg = makeInputBg(),
		anchor = {0, 0, 0, 0},
		w = input_w,
		h = 22,
		padding = {x1, 0, y_off, 0},
		on_submit = function()
			local text = input1:getText()
			if on_change1 and isValidNumber(text) then
				on_change1(text)
			end
		end,
	}))

	local input2
	input2 = row:addChild(TextInput({
		text = val2_str,
		font_size = 11,
		text_color = uc.PRIMARY_TEXT,
		single_line = true,
		v_align = "center",
		bg = makeInputBg(),
		anchor = {0, 0, 0, 0},
		w = input_w,
		h = 22,
		padding = {x2, 0, y_off, 0},
		on_submit = function()
			local text = input2:getText()
			if on_change2 and isValidNumber(text) then
				on_change2(text)
			end
		end,
	}))

	return row, {input1, input2}
end

--------------------------------------------------
-- 颜色行（swatch + 点击弹出 HSV 选色器）
--------------------------------------------------
function Rows.makeColorRow(label_text, getter, setter, onChangeHook)
	local ColorPicker = require "ui_editor.editor.inspector.color_picker"

	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = ROW_H,
		raycast_target = true,
	})
	row:setCustomMinimumSize(nil, ROW_H)

	row:addChild(Text({
		text = label_text,
		font_size = 11,
		text_color = uc.SECONDARY_TEXT,
		v_align = "center",
		anchor = {0, 0, 0, 0},
		w = LABEL_W,
		h = ROW_H,
		padding = {12, 0, 0, 0},
	}))

	local swatch_w = 20
	local swatch_h = 18
	local swatch_y = (ROW_H - swatch_h) / 2
	local swatch_x = LABEL_W + 12

	local swatch = row:addChild(Panel({
		bg_color = {0.5, 0.5, 0.5, 1},
		outline_width = 1,
		outline_color = uc.LINE,
		rounding_radius = 3,
		anchor = {0, 0, 0, 0},
		padding = {swatch_x, 0, swatch_y, 0},
		w = swatch_w,
		h = swatch_h,
	}))
	swatch.raycast_target = true

	-- 当前颜色 hex 显示
	local hex_label = row:addChild(Text({
		text = "#AAAAAA",
		font_size = 10,
		text_color = uc.PRIMARY_TEXT,
		v_align = "center",
		anchor = {0, 0, 0, 0},
		w = 70,
		h = ROW_H,
		padding = {swatch_x + swatch_w + 6, 0, 0, 0},
	}))

	-- 点击色块 → 弹出选色器
	function swatch.onMousePressed(self, mx, my, btn)
		if btn == 1 then
			ColorPicker.showPicker(swatch, getter, setter, onChangeHook)
			return true
		end
		return false
	end

	-- 初始化 + 每帧同步
	local function refreshDisplay()
		local c = getter and getter()
		if c then
			swatch.bg_color = {c[1], c[2], c[3], c[4] or 1}
			local rh = math.floor((c[1] or 0) * 255 + 0.5)
			local rg = math.floor((c[2] or 0) * 255 + 0.5)
			local rb = math.floor((c[3] or 0) * 255 + 0.5)
			hex_label:setText(string.format("#%02X%02X%02X", rh, rg, rb))
		end
	end
	refreshDisplay()

	return row, {swatch = swatch, getter = getter, setter = setter, refreshDisplay = refreshDisplay}
end

--------------------------------------------------
-- 枚举 Dropdown 行
--------------------------------------------------
function Rows.makeDropdownRow(label_text, options, current_value, on_change, onChangeHook)
	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = ROW_H,
	})
	row:setCustomMinimumSize(nil, ROW_H)

	row:addChild(Text({
		text = label_text,
		font_size = 11,
		text_color = uc.SECONDARY_TEXT,
		v_align = "center",
		anchor = {0, 0, 0, 0},
		w = LABEL_W,
		h = ROW_H,
		padding = {12, 0, 0, 0},
	}))

	-- 找到当前值对应的索引
	local selected_idx = 1
	for i, v in ipairs(options) do
		if v == current_value then
			selected_idx = i
			break
		end
	end

	local dd
	dd = row:addChild(Dropdown({
		options = options,
		selected_index = selected_idx,
		max_visible_items = 5,
		anchor = {0, 0, 0, 0},
		w = INPUT_W,
		h = 22,
		padding = {LABEL_W + 12, 0, (ROW_H - 22) / 2, 0},
		on_select = function(_self, idx, val)
			if onChangeHook then onChangeHook() end
			if on_change then on_change(val) end
		end,
	}))

	return row, dd
end

--------------------------------------------------
-- 复选框行（布尔值）
--------------------------------------------------
function Rows.makeCheckboxRow(label_text, current_val, on_change, onChangeHook)
	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = ROW_H,
		raycast_target = true,
	})
	row:setCustomMinimumSize(nil, ROW_H)

	row:addChild(Text({
		text = label_text,
		font_size = 11,
		text_color = uc.SECONDARY_TEXT,
		v_align = "center",
		anchor = {0, 0, 0, 0},
		w = LABEL_W,
		h = ROW_H,
		padding = {12, 0, 0, 0},
	}))

	local cb = CheckboxWidget({
		checked = current_val,
		style = "checkbox",
		box_size = 14,
		anchor = {0, 0, 0, 0},
		padding = {LABEL_W + 12, 0, (ROW_H - 14) / 2, 0},
	})
	cb.raycast_target = false
	cb._mui_type = nil
	row:addChild(cb)

	row._inspector_cb = cb
	row._inspector_cb_onchange = on_change
	row._inspector_cb_hook = onChangeHook
	row.onMousePressed = function(r, mx, my, btn)
		if btn == 1 then
			local cbw = r._inspector_cb
			if r._inspector_cb_hook then r._inspector_cb_hook() end
			local new_val = not cbw:isChecked()
			cbw:setChecked(new_val)
			if r._inspector_cb_onchange then r._inspector_cb_onchange(new_val) end
			return true
		end
		return false
	end

	return row, cb
end

--------------------------------------------------
-- 文本域行（多行输入，可拖拽调节高度，上下布局）
--------------------------------------------------
function Rows.makeTextAreaRow(label_text, value_str, on_change, initial_h)
	local area_h = initial_h or TEXTAREA_DEFAULT_H
	-- 布局: 上边距(4) + 标签(16) + 间距(2) + 文本域(area_h) + 间距(2) + 拖拽柄(6) + 底部容差(20)
	local total_h = 4 + TEXTAREA_LABEL_H + 2 + area_h + 2 + GRIP_H + TEXTAREA_MARGIN

	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = total_h,
		raycast_target = true,
	})
	row:setCustomMinimumSize(nil, total_h)

	-- 标签（顶部左对齐）
	row:addChild(Text({
		text = label_text,
		font_size = 11,
		text_color = uc.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		h = TEXTAREA_LABEL_H,
		padding = {12, 12, 4, 0},
	}))

	-- 多行文本输入
	local input
	input = row:addChild(TextInput({
		text = value_str,
		font_size = 11,
		text_color = uc.PRIMARY_TEXT,
		single_line = false,
		height_adaptive = false,
		bg = makeInputBg(),
		anchor = {0, 0, 1, 0},
		h = area_h,
		padding = {12, 12, 4 + TEXTAREA_LABEL_H + 2, 0},
	}))

	-- 拖拽柄（底部细条，带视觉指示）
	local grip_y = 4 + TEXTAREA_LABEL_H + 2 + area_h + 2
	local grip = row:addChild(Panel({
		bg_color = {uc.BG[1], uc.BG[2], uc.BG[3], 0.3},
		rounding_radius = 2,
		anchor = {0, 0, 1, 0},
		padding = {12, 12, grip_y, 0},
		h = GRIP_H,
	}))
	grip.raycast_target = false
	-- 拖拽柄上画三条短线
	local _grip = grip
	function grip.onDraw(self)
		local gx, gy, gw, gh = self.transform:getGlobalBounds()
		local cx = gx + gw / 2
		local cy = gy + gh / 2
		love.graphics.setColor(0.4, 0.4, 0.45, 0.8)
		local line_w = 20
		for i = -1, 1 do
			love.graphics.line(cx - line_w / 2, cy + i * 3, cx + line_w / 2, cy + i * 3)
		end
	end

	-- 拖拽状态
	row._area_h = area_h
	row._area_input = input
	row._area_grip = grip
	row._grip_dragging = false
	row._grip_start_y = 0
	row._grip_start_h = 0

	-- 鼠标按下：检测是否在拖拽柄区域
	function row.onMousePressed(r, mx, my, btn)
		if btn ~= 1 then return false end
		local lx, ly = r.transform:screenToLocal(mx, my)
		local grip_top = 4 + TEXTAREA_LABEL_H + 2 + r._area_h
		if ly >= grip_top and ly <= grip_top + GRIP_H + 4 then
			r._grip_dragging = true
			r._grip_start_y = my
			r._grip_start_h = r._area_h
			return true
		end
		return false
	end

	-- 拖拽移动
	function row.onMouseMoved(r, mx, my, dx, dy)
		if not r._grip_dragging then return false end
		local new_h = r._grip_start_h + (my - r._grip_start_y)
		new_h = math.max(TEXTAREA_MIN_H, math.min(TEXTAREA_MAX_H, new_h))
		if new_h ~= r._area_h then
			r._area_h = new_h
			-- 更新文本域高度
			r._area_input.transform:setSize(nil, new_h)
			-- 更新拖拽柄 top padding（第三个参数是 top）
			local new_grip_y = 4 + TEXTAREA_LABEL_H + 2 + new_h + 2
			r._area_grip.transform:setPadding(nil, nil, new_grip_y, nil)
			-- 更新行高
			local new_total = 4 + TEXTAREA_LABEL_H + 2 + new_h + 2 + GRIP_H + TEXTAREA_MARGIN
			r.transform:setSize(nil, new_total)
			r:setCustomMinimumSize(nil, new_total)
			-- 通知父容器重排
			if r.parent and r.parent.queueSort then
				r.parent:queueSort()
			end
		end
		return true
	end

	-- 释放
	function row.onMouseReleased(r, mx, my, btn)
		if r._grip_dragging then
			r._grip_dragging = false
			return true
		end
		return false
	end

	return row, input
end

--------------------------------------------------
-- 判断 widget 是否在容器内
--------------------------------------------------
function Rows.isInsideContainer(widget)
	if not widget or not widget.parent then return false end
	local p = widget.parent
	if p._sortChildren then return true end
	if p._name == "scroll_root" then return true end
	return false
end

return Rows
