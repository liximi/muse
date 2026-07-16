# Muse UI Editor — 开发进度

## 分支
`feature/ui-editor`

## 启动方式
```bash
love .          # 默认进编辑器
love . gallery  # Gallery 测试工具
```

## 已完成的模块

### 1. Canvas（设计画布）— `ui_editor/editor/canvas.lua`
- 承载被编辑 UI，`setEditedRoot(root_widget)`
- 设计模式下优先拦截 KeyPressed/Mouse* 事件（INTERCEPT_FIRST 声明）
- 其余事件走正常子节点优先传播
- 点击选中 widget（深度优先命中检测）、P 键切父节点、Esc 取消选中
- E 键切换设计/交互模式（进设计模式调 UiManager:clearFocus()）
- onSelectionChanged 回调通知外部
- 左下角模式提示（NotoSansSC 字体）

### 2. Selection（选中管理）— `ui_editor/editor/selection.lua`
- 选中框绘制（蓝色描边）+ 8 个拖拽手柄
- 手柄命中检测（hitHandle）
- 使用 `getCullAABB()` 获取视觉包围盒

### 3. Inspector（属性面板）— `ui_editor/editor/inspector.lua`
- 右侧 220px 面板
- 根据选中 widget 动态生成属性行
- 当前支持：宽度、高度、锚点 X/Y（min/max 各一个输入）、左/右/上/下间距
- getter 每次从 transform 实时读取，setter 直接写回
- 失焦自动提交 + Enter 提交
- 输入框带 bg Panel 背景 + 垂直居中文本

### 4. TreeView（层级树）— `ui_editor/editor/tree_view.lua`
- 左侧 160px 面板
- 递归显示 widget 树（缩进 + ▾ 箭头）
- 点击节点选中 widget（与 Canvas 双向联动）
- 选中节点高亮

### 5. EditorApp（入口）— `ui_editor/editor/editor_app.lua`
- 三面板布局：TreeView(160) | Canvas(flex) | Inspector(220)
- 演示 UI：Panel(root) → Text(title) + Text(body) + Button(btn)
- 双向连线：Canvas ↔ TreeView ↔ Inspector

### 6. 入口路由 — `main.lua`
- `love .` → 编辑器（默认）
- `love . gallery` → Gallery
- 命令行参数解析（`arg` 表）

### 7. 框架修复（过程中顺手修的）
- `textinput.lua`: onHovered 判空 self.bg
- `textinput.lua`: 光标 + 选区绘制跟随 v_align 垂直偏移

## 文档
- `ui_editor/README.md`
- `ui_editor/docs/architecture.md`（完整架构设计）

## 待开发

| # | 模块 | 说明 |
|---|------|------|
| 4 | mui_serializer | Widget 树 → .mui JSON 导出 |
| 5 | lua_scaffold | 生成 .lua 行为脚本骨架 |
| 6 | MuseEditorRuntime | 单例，解析 .mui → 构建树 → id 查找 |
| 7 | 完整编辑器 App | 工具栏（新建/打开/保存）、撤销/重做、.mui ↔ .lua 文件管理 |

## 关键设计决策
- MuseEditorRuntime 是单例（非基类），开发者调用 `Runtime:build()` + `Runtime:find()`
- .mui 纯布局数据（JSON），.lua 行为脚本（开发者手写）
- .mui 文件名按 snake_case 自动匹配 .lua 类名
- 编辑器本身是 Muse UI 应用（自举）
