--------------------------------------------------
-- inspector/fields.lua — 属性字段定义与重建逻辑
-- 根据选中 widget 的 _mui_type 动态构建属性行
--------------------------------------------------

local Utils = require "ui.utils"
local Rows = require "ui_editor.editor.inspector.rows"

local uc = Utils.UI_COLORS
local SZ = Utils.SIZE_FLAGS
local fmt = Rows.fmt

--------------------------------------------------
-- 从 target 重建全部属性行
-- 参数：inspector — Inspector 实例（需要 _form, _rows, _target, _notifyChange
--        target   — 被检视的 widget
--------------------------------------------------
local function populateFields(inspector, target)
	local form = inspector._form
	form:clearChildren()
	inspector._rows = {}

	if not target then
		inspector._type_label:setText("No selection")
		return
	end

	local mui_type = target._mui_type or ""
	local name = target._name or mui_type or target:__tostring()
	inspector._type_label:setText(name)

	-- 通知变更的钩子
	local function hook()
		inspector:_notifyChange()
	end

	-- =====================
	-- §1 布局（所有 widget）
	-- =====================
	form:addChild(Rows.makeSectionHeader("布局"))

	-- 宽
	local w_row, w_input = Rows.makeTextRow("宽度", fmt(target.transform.w),
		function(v) target.transform:setSize(tonumber(v), nil) end, true)
	form:addChild(w_row)
	table.insert(inspector._rows, {input = w_input, getter = function() return fmt(target.transform.w) end,
		setter = function(v) target.transform:setSize(tonumber(v), nil) end, numeric = true})

	-- 高
	local h_row, h_input = Rows.makeTextRow("高度", fmt(target.transform.h),
		function(v) target.transform:setSize(nil, tonumber(v)) end, true)
	form:addChild(h_row)
	table.insert(inspector._rows, {input = h_input, getter = function() return fmt(target.transform.h) end,
		setter = function(v) target.transform:setSize(nil, tonumber(v)) end, numeric = true})

	-- 锚点
	local a1, a2, a3, a4 = target.transform:getAnchor()
	local ax_row, ax_inputs = Rows.makeRow2("锚点 X", fmt(a1), fmt(a3),
		function(v) target.transform:setAnchor(tonumber(v), nil, nil, nil) end,
		function(v) target.transform:setAnchor(nil, nil, tonumber(v), nil) end)
	form:addChild(ax_row)
	table.insert(inspector._rows, {input = ax_inputs[1],
		getter = function() return fmt(select(1, target.transform:getAnchor())) end,
		setter = function(v) target.transform:setAnchor(tonumber(v), nil, nil, nil) end, numeric = true})
	table.insert(inspector._rows, {input = ax_inputs[2],
		getter = function() return fmt(select(3, target.transform:getAnchor())) end,
		setter = function(v) target.transform:setAnchor(nil, nil, tonumber(v), nil) end, numeric = true})

	local ay_row, ay_inputs = Rows.makeRow2("锚点 Y", fmt(a2), fmt(a4),
		function(v) target.transform:setAnchor(nil, tonumber(v), nil, nil) end,
		function(v) target.transform:setAnchor(nil, nil, nil, tonumber(v)) end)
	form:addChild(ay_row)
	table.insert(inspector._rows, {input = ay_inputs[1],
		getter = function() return fmt(select(2, target.transform:getAnchor())) end,
		setter = function(v) target.transform:setAnchor(nil, tonumber(v), nil, nil) end, numeric = true})
	table.insert(inspector._rows, {input = ay_inputs[2],
		getter = function() return fmt(select(4, target.transform:getAnchor())) end,
		setter = function(v) target.transform:setAnchor(nil, nil, nil, tonumber(v)) end, numeric = true})

	-- 边距
	local pad_fields = {
		{label = "左边距", get = function() return fmt(target.transform.left) end,
			set = function(v) target.transform:setPadding(tonumber(v), nil, nil, nil) end},
		{label = "右边距", get = function() return fmt(target.transform.right) end,
			set = function(v) target.transform:setPadding(nil, tonumber(v), nil, nil) end},
		{label = "上边距", get = function() return fmt(target.transform.top) end,
			set = function(v) target.transform:setPadding(nil, nil, tonumber(v), nil) end},
		{label = "下边距", get = function() return fmt(target.transform.bottom) end,
			set = function(v) target.transform:setPadding(nil, nil, nil, tonumber(v)) end},
	}
	for _, f in ipairs(pad_fields) do
		local row, input = Rows.makeTextRow(f.label, f.get(), f.set, true)
		form:addChild(row)
		table.insert(inspector._rows, {input = input, getter = f.get, setter = f.set, numeric = true})
	end

	-- =====================
	-- §2 容器标志（在容器内时显示）
	-- =====================
	if Rows.isInsideContainer(target) then
		form:addChild(Rows.makeSectionHeader("容器标志"))

		local h_flags_opts = {"Fill", "Fill+Expand", "Shrink Begin", "Shrink Center", "Shrink End"}
		local h_flags_vals = {SZ.FILL, SZ.FILL + SZ.EXPAND, SZ.SHRINK_BEGIN, SZ.SHRINK_CENTER, SZ.SHRINK_END}

		-- h_size_flags
		local cur_h_flags = target.h_size_flags or SZ.FILL
		local cur_h_label = h_flags_opts[1]
		for i, v in ipairs(h_flags_vals) do
			if cur_h_flags == v then cur_h_label = h_flags_opts[i]; break end
		end
		local hf_row, _ = Rows.makeDropdownRow("H 标志", h_flags_opts, cur_h_label,
			function(val)
				for i, opt in ipairs(h_flags_opts) do
					if opt == val then target.h_size_flags = h_flags_vals[i]; break end
				end
			end, hook)
		form:addChild(hf_row)

		-- v_size_flags
		local cur_v_flags = target.v_size_flags or SZ.FILL
		local cur_v_label = h_flags_opts[1]
		for i, v in ipairs(h_flags_vals) do
			if cur_v_flags == v then cur_v_label = h_flags_opts[i]; break end
		end
		local vf_row, _ = Rows.makeDropdownRow("V 标志", h_flags_opts, cur_v_label,
			function(val)
				for i, opt in ipairs(h_flags_opts) do
					if opt == val then target.v_size_flags = h_flags_vals[i]; break end
				end
			end, hook)
		form:addChild(vf_row)

		-- stretch_ratio
		local sr_row, sr_input = Rows.makeTextRow("拉伸比", fmt(target.stretch_ratio),
			function(v) target.stretch_ratio = tonumber(v) or 1.0 end, true)
		form:addChild(sr_row)
		table.insert(inspector._rows, {input = sr_input,
			getter = function() return fmt(target.stretch_ratio) end,
			setter = function(v) target.stretch_ratio = tonumber(v) or 1.0 end, numeric = true})
	end

	-- =====================
	-- §3 外观（Panel / Button）
	-- =====================
	local hasBgColor = target.bg_color ~= nil
	local hasOutlineColor = target.outline_color ~= nil
	if mui_type == "Button" and target.state_styles then
		hasBgColor = true
		hasOutlineColor = true
	end

	if hasBgColor or hasOutlineColor then
		form:addChild(Rows.makeSectionHeader("外观"))

		local is_btn = (mui_type == "Button" and target.state_styles)

		-- bg_color getter/setter
		local bg_getter, bg_setter
		if is_btn then
			bg_getter = function()
				local s = target.state_styles.normal
				return (s and s.bg_color) or {0.2, 0.2, 0.25, 1}
			end
			bg_setter = function(c)
				if not target.state_styles.normal then target.state_styles.normal = {} end
				target.state_styles.normal.bg_color = c
				if target.setState then target:setState(target.cur_state) end
			end
		else
			bg_getter = function() return target.bg_color end
			bg_setter = function(c) target.bg_color = c end
		end

		-- outline_color getter/setter
		local ol_getter, ol_setter
		if is_btn then
			ol_getter = function()
				local s = target.state_styles.normal
				return (s and s.outline_color) or {uc.LINE[1], uc.LINE[2], uc.LINE[3], uc.LINE[4]}
			end
			ol_setter = function(c)
				if not target.state_styles.normal then target.state_styles.normal = {} end
				target.state_styles.normal.outline_color = c
				-- 设置描边色时自动补全描边宽（至少 1px 才可见）
				if not target.state_styles.normal.outline_width or target.state_styles.normal.outline_width == 0 then
					target.state_styles.normal.outline_width = 1
				end
				if target.setState then target:setState(target.cur_state) end
			end
		else
			ol_getter = function() return target.outline_color end
			ol_setter = function(c) target.outline_color = c end
		end

		-- outline_width getter/setter
		local olw_getter, olw_setter
		if is_btn then
			olw_getter = function()
				local s = target.state_styles.normal
				return fmt(s and s.outline_width or 0)
			end
			olw_setter = function(v)
				if not target.state_styles.normal then target.state_styles.normal = {} end
				local w = tonumber(v) or 0
				target.state_styles.normal.outline_width = w
				-- 设置描边宽 >0 时自动补全描边色（Button onDraw 要求两者都存在才绘制）
				if w > 0 and not target.state_styles.normal.outline_color then
					target.state_styles.normal.outline_color = {uc.LINE[1], uc.LINE[2], uc.LINE[3], uc.LINE[4]}
				end
				if target.setState then target:setState(target.cur_state) end
			end
		else
			olw_getter = function() return fmt(target.outline_width) end
			olw_setter = function(v) target.outline_width = tonumber(v) or 0 end
		end

		-- rounding_radius getter/setter
		local rr_getter, rr_setter
		if is_btn then
			rr_getter = function()
				local s = target.state_styles.normal
				return fmt(s and s.rounding_radius or 0)
			end
			rr_setter = function(v)
				if not target.state_styles.normal then target.state_styles.normal = {} end
				target.state_styles.normal.rounding_radius = tonumber(v) or 0
				if target.setState then target:setState(target.cur_state) end
			end
		else
			rr_getter = function() return fmt(target.rounding_radius) end
			rr_setter = function(v) target.rounding_radius = tonumber(v) or 0 end
		end

		-- 创建颜色行
		if hasBgColor then
			local bg_row, bg_data = Rows.makeColorRow("背景色", bg_getter, bg_setter, hook)
			form:addChild(bg_row)
			table.insert(inspector._rows, {type = "color", data = bg_data})
		end
		if hasOutlineColor then
			local ol_row, ol_data = Rows.makeColorRow("描边色", ol_getter, ol_setter, hook)
			form:addChild(ol_row)
			table.insert(inspector._rows, {type = "color", data = ol_data})
		end

		local olw_row, olw_input = Rows.makeTextRow("描边宽", olw_getter(), olw_setter, true)
		form:addChild(olw_row)
		table.insert(inspector._rows, {input = olw_input, getter = olw_getter, setter = olw_setter, numeric = true})

		local rr_row, rr_input = Rows.makeTextRow("圆角", rr_getter(), rr_setter, true)
		form:addChild(rr_row)
		table.insert(inspector._rows, {input = rr_input, getter = rr_getter, setter = rr_setter, numeric = true})
	end

	-- =====================
	-- §4 文本
	-- =====================
	local hasText = (target.getText ~= nil) or (target.setText ~= nil)
	if hasText then
		form:addChild(Rows.makeSectionHeader("文本"))

		local txt_getter = function()
			if target.getText then return target:getText(true) or "" end
			return ""
		end
		local txt_setter = function(v)
			if target.setText then target:setText(v) end
		end
		local txt_row, txt_input = Rows.makeTextAreaRow("文字", txt_getter(), txt_setter)
		form:addChild(txt_row)
		table.insert(inspector._rows, {input = txt_input, getter = txt_getter, setter = txt_setter, numeric = false})
	end

	-- font_size
	local hasFontSize = target.font_size ~= nil
	if not hasFontSize and mui_type == "Button" then
		hasFontSize = true
	end
	if hasFontSize then
		local fs_getter, fs_setter
		if target.font_size ~= nil then
			fs_getter = function() return fmt(target.font_size) end
			fs_setter = function(v)
				target.font_size = tonumber(v) or 14
				if target.updateTextLayout then target:updateTextLayout() end
			end
		elseif mui_type == "Button" then
			fs_getter = function()
				if target.text and target.text.font_size then
					return fmt(target.text.font_size)
				end
				return fmt(14)
			end
			fs_setter = function(v)
				local fs = tonumber(v) or 14
				if target.text then
					target.text.font_size = fs
					target.text:updateTextLayout()
				end
			end
		end
		local fs_row, fs_input = Rows.makeTextRow("字号", fs_getter(), fs_setter, true)
		form:addChild(fs_row)
		table.insert(inspector._rows, {input = fs_input, getter = fs_getter, setter = fs_setter, numeric = true})
	end

	-- text_color
	if target.text_color ~= nil then
		local tc_getter = function() return target.text_color end
		local tc_setter = function(c) target.text_color = c end
		local tc_row, tc_data = Rows.makeColorRow("文字色", tc_getter, tc_setter, hook)
		form:addChild(tc_row)
		table.insert(inspector._rows, {type = "color", data = tc_data})
	end

	-- h_align
	if target.horizontal_align ~= nil then
		local opts = {"left", "center", "right", "justify"}
		local ha_row, _ = Rows.makeDropdownRow("水平对齐", opts, target.horizontal_align,
			function(val) target.horizontal_align = val; target:updateTextLayout() end, hook)
		form:addChild(ha_row)
	end

	-- v_align
	if target.vertical_align ~= nil then
		local opts = {"top", "center", "bottom"}
		local va_row, _ = Rows.makeDropdownRow("垂直对齐", opts, target.vertical_align,
			function(val) target.vertical_align = val end, hook)
		form:addChild(va_row)
	end

	-- =====================
	-- §5 容器（BoxContainer / MarginContainer）
	-- =====================
	local hasContainer = (target.separation ~= nil) or (target.margin_left ~= nil)
	if hasContainer then
		form:addChild(Rows.makeSectionHeader("容器"))

		if target.separation ~= nil then
			-- orientation
			local ori_opts = {"vertical", "horizontal"}
			local cur_ori = target.orientation or "vertical"
			local ori_row, _ = Rows.makeDropdownRow("方向", ori_opts, cur_ori,
				function(val)
					target.orientation = val
					if target.queueSort then target:queueSort() end
				end, hook)
			form:addChild(ori_row)

			-- separation
			local sep_row, sep_input = Rows.makeTextRow("间距", fmt(target.separation),
				function(v) target.separation = tonumber(v) or 0; if target.queueSort then target:queueSort() end end, true)
			form:addChild(sep_row)
			table.insert(inspector._rows, {input = sep_input,
				getter = function() return fmt(target.separation) end,
				setter = function(v) target.separation = tonumber(v) or 0; if target.queueSort then target:queueSort() end end,
				numeric = true})

			-- alignment
			local align_opts = {"begin", "center", "end"}
			local cur_align = target.alignment or "begin"
			local al_row, _ = Rows.makeDropdownRow("对齐", align_opts, cur_align,
				function(val)
					target.alignment = val
					if target.queueSort then target:queueSort() end
				end, hook)
			form:addChild(al_row)

			-- auto_size
			local as_row, _ = Rows.makeCheckboxRow("自动尺寸", target.auto_size or false,
				function(val)
					target.auto_size = val
					if target.queueSort then target:queueSort() end
				end, hook)
			form:addChild(as_row)
		end

		-- MarginContainer
		if target.margin_left ~= nil then
			local margin_fields = {
				{label = "左外边距", get = function() return fmt(target.margin_left) end,
					set = function(v) target.margin_left = tonumber(v) or 0; target:queueSort() end},
				{label = "右外边距", get = function() return fmt(target.margin_right) end,
					set = function(v) target.margin_right = tonumber(v) or 0; target:queueSort() end},
				{label = "上外边距", get = function() return fmt(target.margin_top) end,
					set = function(v) target.margin_top = tonumber(v) or 0; target:queueSort() end},
				{label = "下外边距", get = function() return fmt(target.margin_bottom) end,
					set = function(v) target.margin_bottom = tonumber(v) or 0; target:queueSort() end},
			}
			for _, f in ipairs(margin_fields) do
				local row, input = Rows.makeTextRow(f.label, f.get(), f.set, true)
				form:addChild(row)
				table.insert(inspector._rows, {input = input, getter = f.get, setter = f.set, numeric = true})
			end
		end
	end

	-- =====================
	-- §6 其他控件特定属性
	-- =====================
	if mui_type == "ProgressBar" and target.value ~= nil then
		form:addChild(Rows.makeSectionHeader("进度条"))
		local v_row, v_input = Rows.makeTextRow("值", fmt(target.value),
			function(v) target.value = tonumber(v) or 0 end, true)
		form:addChild(v_row)
		table.insert(inspector._rows, {input = v_input,
			getter = function() return fmt(target.value) end,
			setter = function(v) target.value = tonumber(v) or 0 end, numeric = true})
	end

	if mui_type == "SliderBar" and target._value ~= nil then
		form:addChild(Rows.makeSectionHeader("滑块"))
		local v_row, v_input = Rows.makeTextRow("值", fmt(target._value),
			function(v) target._value = tonumber(v) or 0 end, true)
		form:addChild(v_row)
		table.insert(inspector._rows, {input = v_input,
			getter = function() return fmt(target._value) end,
			setter = function(v) target._value = tonumber(v) or 0 end, numeric = true})
	end

	if mui_type == "TextInput" then
		form:addChild(Rows.makeSectionHeader("输入框"))
		local sl_row, _ = Rows.makeCheckboxRow("单行模式", target.single_line or false,
			function(val) target.single_line = val end, hook)
		form:addChild(sl_row)
	end

	if mui_type == "Checkbox" then
		form:addChild(Rows.makeSectionHeader("复选框"))
		local ck_row, _ = Rows.makeCheckboxRow("勾选", target._checked or false,
			function(val) target:setChecked(val) end, hook)
		form:addChild(ck_row)
	end
end

return populateFields
