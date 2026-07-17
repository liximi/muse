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

--------------------------------------------------
-- 颜色工具：0-1 ↔ 0-255
--------------------------------------------------
local function to255(v) return math.floor(v * 255 + 0.5) end
local function to01(v)  return v / 255 end

local function fmt255(n)
	if n == nil then return "0" end
	return tostring(math.floor(n + 0.5))
end

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
-- 内部：从 RGBA 输入框重建颜色
--------------------------------------------------
local function updateColorFromInputs(inputs, getter, setter, swatch)
	local r = tonumber(inputs[1]:getText()) or 0
	local g = tonumber(inputs[2]:getText()) or 0
	local b = tonumber(inputs[3]:getText()) or 0
	local a = tonumber(inputs[4]:getText()) or 255
	local new_color = {to01(r), to01(g), to01(b), to01(a)}
	if setter then setter(new_color) end
	if swatch then
		swatch.bg_color = {new_color[1], new_color[2], new_color[3], new_color[4]}
	end
end

--------------------------------------------------
-- 颜色行（swatch + RGBA 数字输入）
--------------------------------------------------
function Rows.makeColorRow(label_text, getter, setter, onChangeHook)
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

	local swatch_w = 18
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
	swatch.raycast_target = false

	local input_w = 25
	local total_w = swatch_x + swatch_w + 2
	local field_gap = 1
	local inputs = {}

	local initial = getter and getter() or {0.5, 0.5, 0.5, 1}
	if not initial then initial = {0.5, 0.5, 0.5, 1} end

	for i = 1, 4 do
		local x_off = total_w + (i - 1) * (input_w + field_gap)
		local val = to255(initial[i] or 0)

		local inp
		inp = row:addChild(TextInput({
			text = fmt255(val),
			font_size = 10,
			text_color = uc.PRIMARY_TEXT,
			single_line = true,
			v_align = "center",
			h_align = "center",
			bg = makeInputBg(),
			anchor = {0, 0, 0, 0},
			w = input_w,
			h = 20,
			padding = {x_off, 0, (ROW_H - 20) / 2, 0},
			on_submit = function()
				local txt = inp:getText()
				if isValidNumber(txt) then
					if onChangeHook then onChangeHook() end
					updateColorFromInputs(inputs, getter, setter, swatch)
				end
			end,
		}))
		inputs[i] = inp
	end

	-- 初始化 swatch
	local function refreshSwatch()
		local c = getter and getter()
		if c then
			swatch.bg_color = {c[1], c[2], c[3], c[4] or 1}
		end
	end
	refreshSwatch()

	return row, {swatch = swatch, inputs = inputs, getter = getter, setter = setter, refreshSwatch = refreshSwatch}
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
