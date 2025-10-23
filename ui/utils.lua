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

local grayscale_colors = {
    light = Utils.RGB(245, 245, 245),
    light_gray1 = Utils.RGB(224, 224, 224),
    light_gray2 = Utils.RGB(189, 189, 189),
    light_gray3 = Utils.RGB(110, 110, 110),
    dark_gray1 = Utils.RGB(97, 97, 97),
    dark_gray2 = Utils.RGB(45, 45, 45),
    dark_gray3 = Utils.RGB(30, 30, 30),
    dark = Utils.RGB(18, 18, 18),
}
Utils.UI_COLORS = {
    WHITE = Utils.RGB(255, 255, 255),
    BG = grayscale_colors.dark,
    LINE = grayscale_colors.light_gray3,

    TITLE = grayscale_colors.light,
    PRIMARY_TEXT = grayscale_colors.light_gray2,
    SECONDARY_TEXT = grayscale_colors.light_gray3,
    HINT = grayscale_colors.dark_gray1,

    BTN_NORMAL = grayscale_colors.dark_gray3,
    BTN_HOVER = grayscale_colors.dark_gray2,
    BTN_DISABLED = grayscale_colors.dark_gray2,
    BTN_SELECTED = Utils.RGB(255, 110, 160, 0.35),
    BTN_SELECTED_HOVER = Utils.RGB(255, 110, 160, 0.45),

    PINK = Utils.RGB(245, 105, 160),
    LIGHT_PINK = Utils.RGB(255, 110, 160),
    BLUE = Utils.RGB(39, 170, 225),
    LIGHT_BLUE = Utils.RGB(42, 190, 225),
    YELLOW = Utils.RGB(240, 255, 70),
}


--- 创建一个按钮状态的样式定义
---@param text string|table|nil 接受coloredtext
---@param text_color table|nil
---@param font_size number|nil
---@param bg_color table|nil
---@param outline_width number|nil
---@param outline_color table|nil
---@param offset table|nil {x offset, y offset}
---@param scale table|nil {x scale, y scale}
---@param rounding_radius number|nil 背景矩形的圆角半径
function Utils.newButtonStateStyle(text, text_color, font_size, bg_color, outline_width, outline_color, offset, scale, rounding_radius)
    return {
        text = text,
        text_color = text_color,
        font_size = font_size,
        bg_color = bg_color,
        outline_width = outline_width,
        outline_color = outline_color,
        offset = offset,
        scale = scale,
        rounding_radius = rounding_radius,
    }
end

--- 创建一个图片按钮状态的样式定义
---@param texture love.Image|nil
---@param tint table|nil
---@param text string|table|nil 接受coloredtext
---@param text_color table|nil
---@param font_size number|nil
---@param offset table|nil {x offset, y offset}
---@param scale table|nil {x scale, y scale}
function Utils.newImageButtonStateStyle(texture, tint, text, text_color, font_size, offset, scale)
    return {
        text = text,
        text_color = text_color,
        font_size = font_size,
        texture = texture,
        tint = tint,
        offset = offset,
        scale = scale,
    }
end


return Utils
