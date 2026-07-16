# Muse UI Editor

Muse UI 框架的可视化编辑器。拖拽搭建界面，导出 `.mui` 布局文件，配合 `MuseEditorRuntime` 运行时加载。

## 快速开始

### 打开编辑器

```bash
love . --editor
```

或在 Gallery 中切换到「UI Editor」标签。

### 新建 UI

1. 工具栏 → **新建**
2. 输入类名，如 `SettingsDialog`
3. 编辑器自动生成两个文件：
   - `settings_dialog.mui` — 布局数据
   - `settings_dialog.lua` — 行为脚本骨架

### 在游戏中使用

```lua
local SettingsDialog = require "ui/settings_dialog"

-- 挂载到任意容器
local dialog = my_panel:addChild(SettingsDialog({ anchor = {0, 0, 1, 1} }))
```

## 目录结构

```
ui_editor/
├── README.md
├── docs/
│   └── architecture.md        # 架构设计文档
├── editor/                    # 编辑器本体（LÖVE 应用）
│   ├── editor_app.lua         # 入口，三面板布局
│   ├── canvas.lua             # 设计画布
│   ├── inspector.lua          # 属性面板
│   ├── tree_view.lua          # 层级树
│   ├── mui_serializer.lua     # 导出 .mui
│   └── lua_scaffold.lua       # 生成 .lua 骨架
└── runtime/                   # 运行时（随游戏打包）
    └── muse_editor_runtime.lua # 单例，加载 .mui + id 绑定
```

## 依赖

- LÖVE 11.5+
- Muse UI 框架（同仓库 `ui/`）
- 仅 LuaJIT，无外部依赖
