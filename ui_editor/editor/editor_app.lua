--------------------------------------------------
-- EditorApp — 编辑器入口
-- 后续替换为三面板布局（Tree View + Canvas + Inspector）
-- 当前阶段：Canvas + Selection 验证
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local Box = require "ui.widgets.containers.box_container"
local Canvas = require "ui_editor.editor.canvas"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

--------------------------------------------------
-- 构建演示 UI（模拟被编辑的目标界面）
--------------------------------------------------
local function buildDemoUI()
    local root = Panel({
        anchor = {0.5, 0.5, 0.5, 0.5},
        pivot = {0.5, 0.5},
        w = 320,
        h = 200,
        bg_color = uc.SURFACE,
        outline_width = 1,
        outline_color = uc.LINE,
        rounding_radius = 8,
    })
    -- 给个名字方便 Tree View 显示
    root._name = "Panel (root)"

    local title = root:addChild(Text({
        text = "Hello, Muse Editor!",
        font_size = 20,
        font_key = "default_bold",
        text_color = uc.TITLE,
        h = 28,
        anchor = {0, 0, 1, 0},
        padding = {16, 16, 16, 0},
    }))
    title._name = "Text (title)"

    local body = root:addChild(Text({
        text = "点击任意 widget 即可选中\n按 P 切换到父节点\n按 E 切换设计/交互模式",
        font_size = 13,
        text_color = uc.SECONDARY_TEXT,
        h = 52,
        anchor = {0, 0, 1, 0},
        padding = {16, 16, 52, 0},
    }))
    body._name = "Text (body)"

    local btn = root:addChild(Button({
        text = "点我",
        w = 80,
        h = 28,
        anchor = {1, 1, 1, 1},
        padding = {-96, 16, -44, 16},
    }))
    btn._name = "Button (btn)"

    return root
end

--------------------------------------------------
-- 编辑器入口
--------------------------------------------------
local function EditorApp(parent)
    -- 画布（填满整个窗口）
    local canvas = parent:addChild(Canvas({
        anchor = {0, 0, 1, 1},
        padding = {0, 0, 0, 0},
    }))

    -- 注入演示 UI
    canvas:setEditedRoot(buildDemoUI())
end

return EditorApp
