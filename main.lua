local Loc = require "dependencies.i18n.i18n"()
local Lovebird = require "dependencies.Lovebird.Lovebird"
local utf8 = require "utf8"
local Lf = require "dependencies.loveframes"
Class = require "dependencies.classic"

local CollapsibleScreenEdgePanel = require "ui.collapsible_screen_edge_panel"

local languages = {"zh-cn"}

local front_end = {}


love.load = function()
    -- 加载本地化文本
    for _, lan in ipairs(languages) do
        Loc:load("localization/" .. lan .. ".lua")
    end
    Loc:set_fallback("zh-cn")
    Loc:set_locale("zh-cn")

    --设置字体
	love.graphics.setFont(love.graphics.newFont("fonts/NotoSansSC-VariableFont_wght.ttf", 24))

    --允许键盘重复，这样就可以按住退格一直删除字符
    love.keyboard.setKeyRepeat(true)

    --UI
    front_end.left_panel = CollapsibleScreenEdgePanel(250)
end

love.update = function(dt)
    -- 该方法应该总是在update的顶部使用
    -- 在浏览器里打开'127.0.0.1:8000'来查看控制台
    Lovebird.update(dt)

    Lf.update(dt)
end

function love.keypressed(key, scancode, isrepeat)
    Lf.keypressed(key, isrepeat)
end

function love.textinput(text)
    Lf.textinput(text)
end

function love.keyreleased(key, scancode)
    Lf.keyreleased(key)
end

function love.wheelmoved(x, y)
    Lf.wheelmoved(x, y)
end

function love.mousepressed(x, y, button)
	Lf.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	Lf.mousereleased(x, y, button)
end

love.draw = function()
    love.graphics.clear(1, 1, 1, 1)
    love.graphics.setColor(1, 1, 1, 1)
    Lf.draw()
end
