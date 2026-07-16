--------------------------------------------------
-- EditorApp — 编辑器入口
-- 三面板布局：Tree View（左）+ Canvas（中）+ Inspector（右）
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local Canvas = require "ui_editor.editor.canvas"
local Inspector = require "ui_editor.editor.inspector"
local TreeView = require "ui_editor.editor.tree_view"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local TREE_W = 160
local INSPECTOR_W = 220

--------------------------------------------------
-- 演示 UI
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
    -- 右侧 Inspector
    local inspector = parent:addChild(Inspector({
        anchor = {1, 0, 1, 1},
        pivot = {1, 0},
        padding = {-INSPECTOR_W, 0, 0, 0},
        w = INSPECTOR_W,
    }))

    -- 右侧分隔线
    parent:addChild(Panel({
        bg_color = uc.LINE,
        rounding_radius = 0,
        anchor = {1, 0, 1, 1},
        pivot = {1, 0},
        padding = {-INSPECTOR_W - 1, 0, 0, 0},
        w = 1,
        h = 0,
    }))

    -- 左侧 TreeView
    local tree = parent:addChild(TreeView({
        anchor = {0, 0, 0, 1},
        padding = {0, 0, 0, 0},
        w = TREE_W,
    }))

    -- 左侧分隔线
    parent:addChild(Panel({
        bg_color = uc.LINE,
        rounding_radius = 0,
        anchor = {0, 0, 0, 1},
        padding = {TREE_W, 0, 0, 0},
        w = 1,
        h = 0,
    }))

    -- 中央 Canvas
    local canvas = parent:addChild(Canvas({
        anchor = {0, 0, 1, 1},
        padding = {TREE_W + 1, INSPECTOR_W + 1, 0, 0},
    }))

    -- 注入演示 UI
    local demo = buildDemoUI()
    canvas:setEditedRoot(demo)
    tree:setEditedRoot(demo)

    -- 连线：Canvas 选中 → Inspector + TreeView
    canvas.onSelectionChanged = function(widget)
        inspector:inspect(widget)
        tree:selectWidget(widget)
        tree._dirty = true
    end

    -- 连线：TreeView 选中 → Canvas
    tree.onNodeSelected = function(widget)
        canvas.selection:select(widget)
        inspector:inspect(widget)
    end
end

return EditorApp
