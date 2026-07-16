--------------------------------------------------
-- Inspector — 属性面板
-- 职责：显示选中 widget 的属性，实时编辑
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local TextInput = require "ui.widgets.textinput"
local Button = require "ui.widgets.button"
local Box = require "ui.widgets.containers.box_container"
local Scroll = require "ui.widgets.containers.scroll_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local ROW_H = 28
local LABEL_W = 72
local GAP = 4

local Inspector = Class(Widget, function(self, datas)
    Widget.new(self, "Inspector", datas)
    self.raycast_target = true
    self._target = nil     -- 当前被检视的 widget
    self._rows = {}        -- {label widget, input widget} 用于动态更新
    self._dirty = false    -- 需要重建控件

    self:_buildUI()
end)

--------------------------------------------------
-- UI 构建
--------------------------------------------------

function Inspector:_buildUI()
    -- 标题
    self._header = self:addChild(Text({
        text = "Inspector",
        font_size = 13,
        font_key = "default_bold",
        text_color = uc.HINT,
        h = 24,
        anchor = {0, 0, 1, 0},
        padding = {12, 12, 8, 0},
    }))

    -- 类型 + id 标签
    self._type_label = self:addChild(Text({
        text = "无选中",
        font_size = 12,
        text_color = uc.SECONDARY_TEXT,
        h = 18,
        anchor = {0, 0, 1, 0},
        padding = {12, 12, 36, 0},
    }))

    -- 可滚动属性列表
    self._scroll = self:addChild(Scroll({
        anchor = {0, 0, 1, 1},
        padding = {4, 4, 58, 4},
        enable_scroll_h = false,
    }))

    self._form = Box({
        auto_size = true,
        anchor = {0, 0, 1, 0},
        separation = GAP,
    })
    self._scroll:setItem(self._form)
    self._scroll:setScrollableH(0)
end

--------------------------------------------------
-- 检视目标
--------------------------------------------------

-- 设置检视目标 widget，nil 表示清空
function Inspector:inspect(widget)
    self._target = widget
    self._dirty = true
end

--------------------------------------------------
-- 属性行工厂
--------------------------------------------------

local function makeRow(label_text, value_str, on_change)
    local row = Widget({
        anchor = {0, 0, 1, 0},
        h = ROW_H,
    })
    row:setCustomMinimumSize(nil, ROW_H)

    local lbl = row:addChild(Text({
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
        anchor = {0, 0, 0, 0},
        w = 130,
        h = 22,
        padding = {LABEL_W + 12, 0, (ROW_H - 22) / 2, 0},
        on_submit = function()
            if on_change then on_change(input:getText()) end
        end,
    }))

    return row, input
end

-- 双输入行：两个小输入框（如锚点 min / max）
local function makeRow2(label_text, val1_str, val2_str, on_change1, on_change2)
    local row = Widget({
        anchor = {0, 0, 1, 0},
        h = ROW_H,
    })
    row:setCustomMinimumSize(nil, ROW_H)

    local lbl = row:addChild(Text({
        text = label_text,
        font_size = 11,
        text_color = uc.SECONDARY_TEXT,
        v_align = "center",
        anchor = {0, 0, 0, 0},
        w = LABEL_W,
        h = ROW_H,
        padding = {12, 0, 0, 0},
    }))

    local input_w = 58
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
        anchor = {0, 0, 0, 0},
        w = input_w,
        h = 22,
        padding = {x1, 0, y_off, 0},
        on_submit = function()
            if on_change1 then on_change1(input1:getText()) end
        end,
    }))

    local input2
    input2 = row:addChild(TextInput({
        text = val2_str,
        font_size = 11,
        text_color = uc.PRIMARY_TEXT,
        single_line = true,
        anchor = {0, 0, 0, 0},
        w = input_w,
        h = 22,
        padding = {x2, 0, y_off, 0},
        on_submit = function()
            if on_change2 then on_change2(input2:getText()) end
        end,
    }))

    return row, {input1, input2}
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

--------------------------------------------------
-- 重建属性行
--------------------------------------------------

function Inspector:_rebuild()
    self._form:clearChildren()
    self._rows = {}

    if not self._target then
        self._type_label:setText("无选中")
        return
    end

    local target = self._target
    local name = target._name or target._mui_id or target:__tostring()
    self._type_label:setText(name)

    -- 定义属性行：getter 每次从 widget 实时读取，setter 写回
    local fields = {
        {label = "宽度",
            get = function() return fmt(target.transform.w) end,
            set = function(v) target.transform:setSize(tonumber(v), nil) end},
        {label = "高度",
            get = function() return fmt(target.transform.h) end,
            set = function(v) target.transform:setSize(nil, tonumber(v)) end},
    }

    for _, f in ipairs(fields) do
        local row, input = makeRow(f.label, f.get(), f.set)
        self._form:addChild(row)
        table.insert(self._rows, {input = input, getter = f.get, setter = f.set})
    end

    -- 锚点：四字段，双输入行
    local anchor_fields = {
        {label = "锚点 X",
            get1 = function() local a1 = select(1, target.transform:getAnchor()); return fmt(a1) end,
            get2 = function() local a3 = select(3, target.transform:getAnchor()); return fmt(a3) end,
            set1 = function(v) target.transform:setAnchor(tonumber(v), nil, nil, nil) end,
            set2 = function(v) target.transform:setAnchor(nil, nil, tonumber(v), nil) end},
        {label = "锚点 Y",
            get1 = function() local a2 = select(2, target.transform:getAnchor()); return fmt(a2) end,
            get2 = function() local a4 = select(4, target.transform:getAnchor()); return fmt(a4) end,
            set1 = function(v) target.transform:setAnchor(nil, tonumber(v), nil, nil) end,
            set2 = function(v) target.transform:setAnchor(nil, nil, nil, tonumber(v)) end},
    }

    for _, af in ipairs(anchor_fields) do
        local row, inputs = makeRow2(af.label, af.get1(), af.get2(), af.set1, af.set2)
        self._form:addChild(row)
        table.insert(self._rows, {input = inputs[1], getter = af.get1, setter = af.set1})
        table.insert(self._rows, {input = inputs[2], getter = af.get2, setter = af.set2})
    end

    -- 间距：四字段
    local padding_fields = {
        {label = "左间距",
            get = function() return fmt(target.transform.left) end,
            set = function(v) target.transform:setPadding(tonumber(v), nil, nil, nil) end},
        {label = "右间距",
            get = function() return fmt(target.transform.right) end,
            set = function(v) target.transform:setPadding(nil, tonumber(v), nil, nil) end},
        {label = "上间距",
            get = function() return fmt(target.transform.top) end,
            set = function(v) target.transform:setPadding(nil, nil, tonumber(v), nil) end},
        {label = "下间距",
            get = function() return fmt(target.transform.bottom) end,
            set = function(v) target.transform:setPadding(nil, nil, nil, tonumber(v)) end},
    }

    for _, f in ipairs(padding_fields) do
        local row, input = makeRow(f.label, f.get(), f.set)
        self._form:addChild(row)
        table.insert(self._rows, {input = input, getter = f.get, setter = f.set})
    end
end

--------------------------------------------------
-- 更新
--------------------------------------------------

function Inspector:onUpdate(dt)
    if self._dirty then
        self:_rebuild()
        self._dirty = false
    end

    if self._target then
        for _, entry in ipairs(self._rows) do
            local input = entry.input
            local was_focused = entry._was_focused
            local is_focused = input:isFocus()

            -- 失焦提交：焦点从有变无，且文本与当前值不同 → 触发 setter
            if was_focused and not is_focused then
                local current = entry.getter()
                if input:getText() ~= current then
                    entry.setter(input:getText())
                end
            end

            entry._was_focused = is_focused

            -- 无焦点时刷新显示值（外部变更同步）
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
