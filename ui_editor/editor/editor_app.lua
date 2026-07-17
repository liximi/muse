--------------------------------------------------
-- EditorApp — 编辑器入口
-- 布局：TreeView（左）+ Canvas（中）+ Inspector（右）+ Toolbar（底）
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local Canvas = require "ui_editor.editor.canvas"
local Inspector = require "ui_editor.editor.inspector"
local TreeView = require "ui_editor.editor.tree_view"
local Toolbar = require "ui_editor.editor.toolbar"
local WidgetPalette = require "ui_editor.editor.widget_palette"
local UndoManager = require "ui_editor.editor.undo_manager"
local Serializer = require "ui_editor.editor.mui_serializer"
local Scaffold = require "ui_editor.editor.lua_scaffold"
local LEAF_TYPES = require "ui_editor.editor.widget_meta"
local BoxContainer = require "ui.widgets.containers.box_container"
local Utils = require "ui.utils"
local FileUtils = require "ui_editor.editor.file_utils"
local ProjectDialog = require "ui_editor.editor.project_dialog"

local uc = Utils.UI_COLORS

local TREE_W = 160
local INSPECTOR_W = 220
local TOOLBAR_H = 32
local PALETTE_H = 180

--------------------------------------------------
-- 演示 UI（快速启动时使用）
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
    root._mui_id = "root"
    root._mui_type = "Panel"
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
    title._mui_id = "title"
    title._mui_type = "Text"
    title._name = "Text (title)"

    local body = root:addChild(Text({
        text = "Click to select a widget\nCtrl+Z Undo  Ctrl+Y Redo  Ctrl+S Save",
        font_size = 13,
        text_color = uc.SECONDARY_TEXT,
        h = 52,
        anchor = {0, 0, 1, 0},
        padding = {16, 16, 52, 0},
    }))
    body._mui_id = "body"
    body._mui_type = "Text"
    body._name = "Text (body)"

    local btn = root:addChild(Button({
        text = "Click me",
        w = 80,
        h = 28,
        anchor = {1, 1, 1, 1},
        padding = {-96, 16, -44, 16},
    }))
    btn._mui_id = "ok_btn"
    btn._mui_type = "Button"
    btn._name = "Button (ok_btn)"

    return root
end

--------------------------------------------------
-- 创建空根 Panel
--------------------------------------------------
local function createEmptyRoot(className)
    local root = Panel({
        anchor = {0.5, 0.5, 0.5, 0.5},
        pivot = {0.5, 0.5},
        w = 400,
        h = 300,
        bg_color = uc.SURFACE,
        outline_width = 1,
        outline_color = uc.LINE,
        rounding_radius = 8,
    })
    root._mui_id = "root"
    root._mui_type = "Panel"
    root._name = className or "Untitled"
    return root
end

--------------------------------------------------
-- 编辑器入口
--------------------------------------------------
local function EditorApp(parent)
    -- === 状态 ===
    local state = {
        current_file = nil,       -- 当前编辑的 .mui 文件名
        project_dir = nil,        -- 项目根目录
        class_name = nil,
        undo_mgr = UndoManager(50),
        project_selected = false, -- 用户是否已选择项目
    }

    -- === 右侧 Inspector ===
    local inspector = parent:addChild(Inspector({
        anchor = {1, 0, 1, 1},
        pivot = {1, 0},
        padding = {-INSPECTOR_W, 0, 0, TOOLBAR_H},
        w = INSPECTOR_W,
    }))

    -- 右侧分隔线
    parent:addChild(Panel({
        bg_color = uc.LINE,
        rounding_radius = 0,
        anchor = {1, 0, 1, 1},
        pivot = {1, 0},
        padding = {-INSPECTOR_W - 1, 0, 0, TOOLBAR_H},
        w = 1,
        h = 0,
    }))

    -- === 左侧 TreeView（上方）===
    local tree = parent:addChild(TreeView({
        anchor = {0, 0, 0, 1},
        padding = {0, 0, 0, TOOLBAR_H + PALETTE_H + 1},
        w = TREE_W,
        v_size_flags = 0,
    }))
    tree:setCustomMinimumSize(nil, 60)

    -- TreeView / Palette 分隔线
    parent:addChild(Panel({
        bg_color = uc.LINE,
        rounding_radius = 0,
        anchor = {0, 1, 0, 1},
        pivot = {0, 1},
        padding = {0, 0, -(PALETTE_H + TOOLBAR_H + 1), -(PALETTE_H + TOOLBAR_H)},
        w = TREE_W,
        h = 1,
    }))

    -- === 左侧 Palette（下方）===
    local palette = parent:addChild(WidgetPalette({
        anchor = {0, 1, 0, 1},
        pivot = {0, 1},
        padding = {0, 0, -(PALETTE_H + TOOLBAR_H), -TOOLBAR_H},
        w = TREE_W,
        h = PALETTE_H,
    }))

    -- 左侧分隔线
    parent:addChild(Panel({
        bg_color = uc.LINE,
        rounding_radius = 0,
        anchor = {0, 0, 0, 1},
        padding = {TREE_W, 0, 0, TOOLBAR_H},
        w = 1,
        h = 0,
    }))

    -- === 中央 Canvas ===
    local canvas = parent:addChild(Canvas({
        anchor = {0, 0, 1, 1},
        padding = {TREE_W + 1, INSPECTOR_W + 1, 0, TOOLBAR_H},
    }))

    -- === 底部背景（先添加 → 在 Toolbar 下层）===
    parent:addChild(Panel({
        bg_color = { uc.BG[1] * 0.95, uc.BG[2] * 0.95, uc.BG[3] * 0.95, 1 },
        rounding_radius = 0,
        anchor = {0, 1, 1, 1},
        pivot = {0, 1},
        padding = {0, 0, -TOOLBAR_H, 0},
        w = 0,
        h = TOOLBAR_H,
        outline_width = 0,
    }))

    -- === 底部 Toolbar ===
    local toolbar = parent:addChild(Toolbar({
        anchor = {0, 1, 1, 1},
        pivot = {0, 1},
        padding = {0, 0, -TOOLBAR_H, 0},
        h = TOOLBAR_H,
    }))

    -- === 创建空 UI（等待项目选择后填充）===
    local currentRoot = createEmptyRoot("Untitled")
    canvas:setEditedRoot(currentRoot)
    tree:setEditedRoot(currentRoot)
    state.class_name = "Untitled"
    state.undo_mgr:pushSnapshot(currentRoot)

    -- === 显示项目选择对话框 ===
    ProjectDialog.show(function(project_dir)
        state.project_dir = project_dir
        state.project_selected = true
        state.current_file = nil
        print("[Editor] Project: " .. project_dir)
        -- 可以选择打开已有文件或开始新建
    end)

    -- === 连线：选中联动 ===

    canvas.onSelectionChanged = function(widget)
        inspector:inspect(widget)
        tree:selectWidget(widget)
        tree._dirty = true
    end

    tree.onNodeSelected = function(widget)
        canvas.selection:select(widget)
        inspector:inspect(widget)
    end

    -- === 撤销：Inspector 属性变更前自动拍快照 ===
    inspector.onBeforePropertyChange = function(target)
        if target then
            state.undo_mgr:pushSnapshot(canvas:getEditedRoot())
        end
    end

    -- === 撤销：Canvas 拖拽/缩放前拍快照 ===
    canvas.onBeforeModify = function(widget)
        state.undo_mgr:pushSnapshot(canvas:getEditedRoot())
    end

    -- =========================================
    -- 操作函数（必须在回调注册前定义！）
    -- =========================================

    -- === 工具函数：获取插入目标 parent ===
    -- 任何 widget 都可以作为父容器（内部子结构如 Button.text 不带 _mui_type，
    -- 命中检测会跳过它们，不影响编辑器操作）
    local function getInsertParent()
        local sel = canvas.selection.widget
        if not sel then return canvas:getEditedRoot() end
        return sel
    end

    -- === 创建 Widget ===
    local function doCreateWidget(widgetType)
        local root = canvas:getEditedRoot()
        if not root then return end

        local parent = getInsertParent()
        if not parent then return end

        state.undo_mgr:pushSnapshot(root)

        local newWidget = WidgetPalette.createWidget(widgetType)
        if not newWidget then return end

        parent:addChild(newWidget)

        -- 刷新树并选中新 widget
        tree:setEditedRoot(root)
        tree:selectWidget(newWidget)
        canvas.selection:select(newWidget)
        canvas:_notifySelection()
        inspector:inspect(newWidget)
        print("[Editor] Created " .. widgetType)
    end

    -- === 删除 Widget ===
    local function doDeleteWidget(widget)
        local root = canvas:getEditedRoot()
        if not widget or widget == root then return end

        local parent = widget.parent
        if not parent or parent == canvas then return end

        state.undo_mgr:pushSnapshot(root)

        -- 如果正在删除的是当前选中的 widget，先取消选中
        if canvas.selection.widget == widget then
            canvas.selection:deselect()
            canvas:_notifySelection()
            inspector:inspect(nil)
        end

        parent:removeChild(widget)
        tree:setEditedRoot(root)
        print("[Editor] Deleted " .. (widget._mui_id or widget._name or "widget"))
    end

    local function doDelete()
        doDeleteWidget(canvas.selection.widget)
    end

    local function doNew()
        local newRoot = createEmptyRoot("Untitled")
        canvas:setEditedRoot(newRoot)
        tree:setEditedRoot(newRoot)
        inspector:inspect(nil)
        state.current_file = nil
        state.class_name = "Untitled"
        state.undo_mgr:clear()
        state.undo_mgr:pushSnapshot(newRoot)
        canvas.selection:deselect()
        canvas:_notifySelection()
        print("[Editor] New UI")
    end

    local function doSave()
        local root = canvas:getEditedRoot()
        if not root then return end

        if state.current_file then
            local savePath = FileUtils.joinPath(state.project_dir or ".", state.current_file)
            if Serializer.save(root, savePath) then
                print("[Editor] Saved: " .. savePath)
            end
        else
            local start_dir = state.project_dir or "."
            local path = FileUtils.nativeSaveFile(start_dir,
                (state.class_name or "untitled") .. ".mui")
            if path then
                if Serializer.save(root, path) then
                    state.project_dir = FileUtils.getParentPath(path)
                    state.current_file = FileUtils.getFileName(path)
                    ProjectDialog.addRecentProject(state.project_dir)
                    print("[Editor] Saved: " .. path)
                end
            end
        end
    end

    local function doExport()
        local root = canvas:getEditedRoot()
        if not root then return end
        local className = state.class_name or "Untitled"

        if not state.current_file then
            local path = FileUtils.nativeSaveFile(
                state.project_dir or ".",
                (className or "untitled") .. ".mui")
            if path then
                if Serializer.save(root, path) then
                    state.project_dir = FileUtils.getParentPath(path)
                    state.current_file = FileUtils.getFileName(path)
                    ProjectDialog.addRecentProject(state.project_dir)
                    local luaPath = path:gsub("%.mui$", ".lua")
                    if Scaffold.save(root, className, path, luaPath) then
                        print("[Editor] Exported: " .. path .. " + " .. luaPath)
                    end
                end
            end
        else
            local muiPath = FileUtils.joinPath(state.project_dir or ".", state.current_file)
            Serializer.save(root, muiPath)
            local luaPath = muiPath:gsub("%.mui$", ".lua")
            if Scaffold.save(root, className, muiPath, luaPath) then
                print("[Editor] Exported: " .. muiPath .. " + " .. luaPath)
            end
        end
    end

    local function doOpen()
        local start_dir = state.project_dir or "."
        local path = FileUtils.nativeOpenFile(start_dir)
        if not path then return end

        local Runtime = require("ui_editor.runtime.muse_editor_runtime"):getInstance()
        Runtime:clearCache()
        local root = Runtime:buildRoot(path)
        if root then
            state.project_dir = FileUtils.getParentPath(path)
            state.current_file = FileUtils.getFileName(path)
            ProjectDialog.addRecentProject(state.project_dir)

            local baseName = state.current_file:gsub("%.mui$", "")
            state.class_name = baseName:gsub("^%l", string.upper)

            canvas:setEditedRoot(root)
            tree:setEditedRoot(root)
            inspector:inspect(nil)
            canvas.selection:deselect()
            canvas:_notifySelection()
            state.undo_mgr:clear()
            state.undo_mgr:pushSnapshot(root)
            print("[Editor] Opened: " .. path)
        end
    end

    local function doUndo()
        local root = canvas:getEditedRoot()
        if not root then return end
        if state.undo_mgr:undo(root) then
            canvas.selection:deselect()
            canvas:_notifySelection()
            inspector:inspect(nil)
            tree:setEditedRoot(root)
            tree._dirty = true
            print("[Editor] Undo")
        end
    end

    local function doRedo()
        local root = canvas:getEditedRoot()
        if not root then return end
        if state.undo_mgr:redo(root) then
            canvas.selection:deselect()
            canvas:_notifySelection()
            inspector:inspect(nil)
            tree:setEditedRoot(root)
            tree._dirty = true
            print("[Editor] Redo")
        end
    end

    -- =========================================
    -- 回调注册
    -- =========================================

    -- === 快捷键：Canvas 委托给编辑器级处理 ===
    canvas.onShortcut = function(key, ctrl)
        if ctrl and key == "z" then
            doUndo()
            return true
        elseif ctrl and key == "y" then
            doRedo()
            return true
        elseif ctrl and key == "s" then
            doSave()
            return true
        elseif ctrl and key == "n" then
            doNew()
            return true
        elseif key == "delete" then
            doDelete()
            return true
        end
        return false
    end

    -- === TreeView 右键删除 ===
    tree.onNodeDelete = function(widget)
        doDeleteWidget(widget)
    end

    -- === Palette 创建 widget ===
    palette.onWidgetCreate = function(widgetType)
        doCreateWidget(widgetType)
    end

    -- === 工具栏回调 ===
    toolbar.onNew = doNew
    toolbar.onSave = doSave
    toolbar.onExport = doExport
    toolbar.onOpen = doOpen
    toolbar.onUndo = doUndo
    toolbar.onRedo = doRedo
end

return EditorApp
