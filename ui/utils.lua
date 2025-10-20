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
    },
    SHADOW_DEFAULT_PROPS = {
        OFFSET = {5, 5},
        COLOR = {0, 0, 0, 0.35},
        BLUR = 10,
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
    PALE_GRAY2 = Utils.RGB(190, 190, 190),
    PALE_GRAY3 = Utils.RGB(160, 160, 160),
    NEUTRAL_GRAY = Utils.RGB(128, 128, 128),
    DARK_GRAY = Utils.RGB(51, 51, 51),
    BLACK = Utils.RGB(37, 37, 37),
    BLACK2 = Utils.RGB(32, 32, 32),
    PINK = Utils.RGB(233, 150, 200),
    YELLOW = Utils.RGB(240, 255, 70),
    BLUE = Utils.RGB(100, 180, 210),

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


local shader_content, err = love.filesystem.read("ui/shaders/rounded_rect_shadow.frag")
local roundedShadowShader = love.graphics.newShader(shader_content)
---@param center table {x, y} 矩形中心
---@param half_size table {x, y} 半尺寸
---@param sigma number 模糊半径
---@param corner number 圆角半径
---@param shadow_offset table {x, y} 阴影偏移
---@param shadow_color table {r, g, b, a} 阴影颜色
function Utils.getDropShadowShader(center, half_size, sigma, corner, shadow_offset, shadow_color)
    roundedShadowShader:send("center", center)
    roundedShadowShader:send("halfSize", half_size)
    roundedShadowShader:send("sigma", sigma)
    roundedShadowShader:send("corner", corner)
    roundedShadowShader:send("shadowOffset", shadow_offset)
    roundedShadowShader:send("shadowColor", shadow_color)
    return roundedShadowShader
end

local blur_canvas = love.graphics.newCanvas()
local canvas_size = {love.graphics:getWidth(), love.graphics:getHeight()}
---@param rect table {x, y, w, h} 矩形信息
---@param sigma number 模糊半径
---@param corner number 圆角半径
---@param shadow_offset table {x, y} 阴影偏移
---@param shadow_color table {r, g, b, a} 阴影颜色
function Utils.drawRectangleShadow(rect, sigma, corner, shadow_offset, shadow_color)
    local screen_size = {love.graphics:getWidth(), love.graphics:getHeight()}
    if canvas_size[1] ~= screen_size[1] or canvas_size[2] ~= screen_size[2] then
        canvas_size = screen_size
        blur_canvas = love.graphics.newCanvas()
    end
    love.graphics.setCanvas(blur_canvas)
        love.graphics.setColor({1, 1, 1, 1})
        love.graphics.clear()
        local half_size = {rect[3] / 2, rect[4] / 2}
        local center = {rect[1] + half_size[1], rect[2] + half_size[2]}
        local shadow_shader = Utils.getDropShadowShader(center, half_size, sigma, corner, shadow_offset, shadow_color)
        love.graphics.setShader(shadow_shader)
            love.graphics.rectangle("fill", 0, 0, canvas_size[1], canvas_size[2])
        love.graphics.setShader()
    love.graphics.setCanvas()

    love.graphics.draw(blur_canvas)
end


return Utils
