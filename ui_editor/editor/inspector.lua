--------------------------------------------------
-- Inspector — 属性面板
-- 职责：显示选中 widget 的属性，实时编辑
--
-- 模块拆分：
--   inspector/rows.lua   — 行工厂（文本/颜色/Dropdown/Checkbox）
--   inspector/fields.lua — _rebuild 属性字段映射
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local BoxContainer = require "ui.widgets.containers.box_container"
local Scroll = require "ui.widgets.containers.scroll_container"
local Utils = require "ui.utils"

local Rows = require "ui_editor.editor.inspector.rows"
local populateFields = require "ui_editor.editor.inspector.fields"

local uc = Utils.UI_COLORS
local isValidNumber = Rows.isValidNumber

--------------------------------------------------
-- Inspector 主类
--------------------------------------------------

local Inspector = Class(Widget, function(self, datas)
	Widget.new(self, "Inspector", datas)
	self.raycast_target = true
	self._target = nil
	self._rows = {}
	self._dirty = false
	self.onBeforePropertyChange = nil
	self:_buildUI()
end)

--------------------------------------------------
-- UI 构建
--------------------------------------------------

function Inspector:_buildUI()
	self._header = self:addChild(Text({
		text = "Inspector",
		font_size = 13,
		font_key = "default_bold",
		text_color = uc.HINT,
		h = 24,
		anchor = {0, 0, 1, 0},
		padding = {12, 12, 8, 0},
	}))

	self._type_label = self:addChild(Text({
		text = "No selection",
		font_size = 12,
		text_color = uc.SECONDARY_TEXT,
		h = 18,
		anchor = {0, 0, 1, 0},
		padding = {12, 12, 36, 0},
	}))

	self._scroll = self:addChild(Scroll({
		anchor = {0, 0, 1, 1},
		padding = {4, 4, 58, 4},
		enable_scroll_h = false,
	}))

	self._form = BoxContainer({
		auto_size = true,
		anchor = {0, 0, 1, 0},
		separation = 4,
	})
	self._scroll:setItem(self._form)
	self._scroll:setScrollableH(0)
end

--------------------------------------------------
-- 检视目标
--------------------------------------------------

function Inspector:inspect(widget)
	self._target = widget
	self._dirty = true
end

--------------------------------------------------
-- 通知变更（触发撤销快照）
--------------------------------------------------
function Inspector:_notifyChange()
	if self.onBeforePropertyChange then
		self.onBeforePropertyChange(self._target)
	end
end

--------------------------------------------------
-- 重建属性行（委托给 fields 模块）
--------------------------------------------------
function Inspector:_rebuild()
	populateFields(self, self._target)
end

--------------------------------------------------
-- 每帧同步：失焦提交 + 外部变更回显
--------------------------------------------------
function Inspector:onUpdate(dt)
	if self._dirty then
		self:_rebuild()
		self._dirty = false
	end

	if not self._target then return end

	for _, entry in ipairs(self._rows) do
		-- 颜色行：同步色块和 RGBA 输入
		if entry.type == "color" then
			local data = entry.data
			local c = data.getter and data.getter()
			if c then
				data.swatch.bg_color = {c[1], c[2], c[3], c[4] or 1}
				-- 仅在无焦点时同步 RGBA 输入
				local all_unfocused = true
				for i = 1, 4 do
					if data.inputs[i]:isFocus() then
						all_unfocused = false
						break
					end
				end
				if all_unfocused then
					for i = 1, 4 do
						local v255 = math.floor((c[i] or 0) * 255 + 0.5)
						local expected_str = tostring(v255)
						if data.inputs[i]:getText() ~= expected_str then
							data.inputs[i]:setText(expected_str)
						end
					end
				end
			end

		-- 文本/数字行：失焦提交 + 同步
		elseif entry.input then
			local input = entry.input
			local was_focused = entry._was_focused
			local is_focused = input:isFocus()

			if was_focused and not is_focused then
				local current = entry.getter()
				local text = input:getText()
				if text ~= current then
					if entry.numeric and not isValidNumber(text) then
						input:setText(current)
					else
						self:_notifyChange()
						entry.setter(text)
					end
				end
			end

			entry._was_focused = is_focused

			if not is_focused then
				local current = entry.getter()
				if input:getText() ~= current then
					input:setText(current)
				end
			end
		end
	end
end

return Inspector
