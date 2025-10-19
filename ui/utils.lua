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


local roundedShadowShader = love.graphics.newShader([[
    uniform vec2 center;       // 圆角矩形中心（窗口坐标，如 (400, 300)）
    uniform vec2 halfSize;     // 圆角矩形半尺寸（宽/2, 高/2，如 (100,50)→实际200x100）
    uniform float sigma;       // 阴影模糊半径（2~20 为宜）
    uniform float corner;      // 圆角半径（0=方形，最大不超过 min(halfSize.x, halfSize.y)）
    uniform vec2 shadowOffset; // 阴影偏移（x右移，y下移，如 (8,8)）
    uniform vec4 shadowColor;  // 阴影颜色（RGBA，如 (0,0,0,0.5)→半透黑）
    // 1. 误差函数（erf）近似
    vec2 erf(vec2 x) {
        vec2 s = sign(x);
        vec2 a = abs(x);
        x = 1.0 + (0.278393 + (0.230389 + 0.078108 * (a * a)) * a) * a;
        x *= x;
        return s - s / (x * x);
    }
    // 2. 高斯函数
    float gaussian(float x, float sigma) {
        const float pi = 3.141592653589793;
        return exp(-(x * x) / (2.0 * sigma * sigma)) / (sqrt(2.0 * pi) * sigma);
    }
    // 3. x方向闭式解
    float roundedBoxShadowX(float x, float y, float sigma, float corner, vec2 halfSize) {
        float delta = min(halfSize.y - corner - abs(y), 0.0);
        float curvedX = halfSize.x - corner + sqrt(max(0.0, corner * corner - delta * delta));
        vec2 integral = 0.5 + 0.5 * erf((x + vec2(-curvedX, curvedX)) * (sqrt(0.5) / sigma));
        return integral.y - integral.x;
    }
    // 4. 圆角阴影主函数
    float roundedBoxShadow(vec2 point, vec2 halfSize, float sigma, float corner) {
        float safeSigma = max(sigma, 0.1); // 避免 sigma=0 导致计算错误
        float safeCorner = clamp(corner, 0.0, min(halfSize.x, halfSize.y)); // 限制圆角最大范围

        // 确定 y 方向采样范围（高斯 3σ 外贡献 <0.3%，无需采样）
        float lowY = point.y - halfSize.y;
        float highY = point.y + halfSize.y;
        float sampleStart = clamp(-3.0 * safeSigma, lowY, highY);
        float sampleEnd = clamp(3.0 * safeSigma, lowY, highY);

        // 4点采样（平衡精度与性能）
        float sampleStep = (sampleEnd - sampleStart) / 4.0;
        float ySample = sampleStart + sampleStep * 0.5;
        float shadowIntensity = 0.0;

        for (int i = 0; i < 4; i++) {
            shadowIntensity += roundedBoxShadowX(point.x, point.y - ySample, safeSigma, safeCorner, halfSize)
                            * gaussian(ySample, safeSigma)
                            * sampleStep;
            ySample += sampleStep;
        }

        return clamp(shadowIntensity, 0.0, 1.0);
    }
    // 片元着色器入口函数
    // - color：顶点传递的颜色
    // - texture：当前绑定的纹理（此处不用，忽略）
    // - texcoord：纹理坐标（此处不用，忽略）
    // - pixcoord：当前像素的窗口坐标（左上角为原点）
    vec4 effect(vec4 color, Image texture, vec2 texcoord, vec2 pixcoord) {
        // 关键：用 pixcoord 获取当前像素的窗口坐标（替代之前错误的 gl_FragCoord）
        // 计算阴影位置 = 像素坐标 - 阴影偏移（阴影在原矩形的偏移方向）
        vec2 shadowPos = pixcoord - shadowOffset;
        // 转换为“相对于矩形中心的坐标”（算法要求的中心化坐标）
        vec2 point = shadowPos - center;
        // 计算阴影强度，叠加颜色（color 是顶点颜色，此处乘 1.0 表示不修改）
        float intensity = roundedBoxShadow(point, halfSize, sigma, corner);
        return intensity * shadowColor * color;
    }
]])
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
---@param center table {x, y} 矩形中心
---@param half_size table {x, y} 半尺寸
---@param sigma number 模糊半径
---@param corner number 圆角半径
---@param shadow_offset table {x, y} 阴影偏移
---@param shadow_color table {r, g, b, a} 阴影颜色
---@param rotation number 旋转弧度
function Utils.drawRectangleShadow(center, half_size, sigma, corner, shadow_offset, shadow_color, rotation)
    local screen_size = {love.graphics:getWidth(), love.graphics:getHeight()}
    if canvas_size[1] ~= screen_size[2] or canvas_size[2] ~= screen_size[2] then
        canvas_size = screen_size
        blur_canvas = love.graphics.newCanvas()
    end
    local canvas_center = {canvas_size[1]/2, canvas_size[2]/2}
    love.graphics.setCanvas(blur_canvas)
        love.graphics.setColor({1, 1, 1, 1})
        love.graphics.clear()
        local shadow_shader = Utils.getDropShadowShader(canvas_center, half_size, sigma, corner, shadow_offset, shadow_color)
        love.graphics.setShader(shadow_shader)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setShader()
    love.graphics.setCanvas()

    love.graphics.push()
        love.graphics.translate(center[1], center[2])
        love.graphics.rotate(rotation)
        love.graphics.draw(blur_canvas, -center[1], -center[2])
    love.graphics.pop()
end


return Utils
