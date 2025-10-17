local Utils = {
    TWO_PI = math.pi * 2,
    TEXT_WRAP_MODE = {
        OFF = "off",
        DEFAULT = "default",
    },
    TEXT_OVERFLOW_MODE = {
        NONE = "none",--不修剪文本
        CHAR = "char"--逐字符修剪文本
    },
    ANCHORS_HORI = {
        LEFT = "left",
        MIDDLE = "middle",
        RIGHT = "right",
    },
    ANCHORS_VERT = {
        TOP = "top",
        MIDDLE = "middle",
        BOTTOM = "bottom",
    },
    BTN_STATES = {
        NORMAL = "normal",
        PRESSED = "pressed",
        DISABLED = "disabled",
        SELECTED = "selected",
        HOVER = "hover",
        SELECTED_HOVER = "selected_hover",
    }
}


--- 构造颜色对象
---@param r number 红色通道的值 0~255
---@param g number 绿色通道的值 0~255
---@param b number 蓝色通道的值 0~255
---@param a number|nil 不透明度通道的值 0~1 默认为 1
function Utils.RGB(r, g, b, a)
    return {r / 255, g / 255, b / 255, a or 1}
end

Utils.UI_COLORS = {
    WHITE = Utils.RGB(255, 255, 255),
    PALE_GRAY = Utils.RGB(220, 220, 220),
    PALE_GRAY2 = Utils.RGB(200, 200, 200),
    NEUTRAL_GRAY = Utils.RGB(128, 128, 128),
    DARK_GRAY = Utils.RGB(51, 51, 51),
    BLACK = Utils.RGB(37, 37, 37),
    BLACK2 = Utils.RGB(32, 32, 32),
    PINK = Utils.RGB(255, 70, 150),
    YELLOW = Utils.RGB(240, 255, 70),
    BLUE = Utils.RGB(41, 170, 226),

    PRIMARY_TEXT = Utils.RGB(220, 220, 220),   --主要文本颜色
    SECONDARY_TEXT = Utils.RGB(128, 128, 128),   --次要文本颜色
}


--- 创建一个按钮状态的样式定义
--- @param text string|table 接受coloredtext
---@param text_color table
---@param bg_color table
---@param outline_color table
---@param offset table {x offset, y offset}
---@param scale table {x scale, y scale}
---@param rounding_radius number 背景矩形的圆角半径
function Utils.newButtonStateStyle(text, text_color, bg_color, outline_color, offset, scale, rounding_radius)
    return {
        text = text,
        text_color = text_color,
        bg_color = bg_color,
        outline_color = outline_color,
        offset = offset,
        scale = scale,
        rounding_radius = rounding_radius,
    }
end


return Utils
