# 架构设计

## 一、设计哲学

**布局即数据，脚本即行为，绑定走 Runtime。**

| 层 | 格式 | 谁产出 | 职责 |
|----|------|--------|------|
| `.mui` | JSON | 编辑器 | 纯布局数据：widget 树、id、属性 |
| `.lua` | Lua | 开发者 | 行为逻辑：继承 Widget，通过 Runtime 绑定子 widget |
| Runtime | Lua 单例 | 框架 | 解析 .mui → 构建树 → id 查找 |

## 二、数据流

```
编辑器拖拽编辑
      │
      ▼
  .mui 文件（JSON）
      │
      ▼  Runtime:loadMui()
  Lua table（widget 树描述）
      │
      ▼  Runtime:build(parent, path)
  Muse Widget 树（真实渲染）
      │
      ▼  Runtime:find(root, "id")
  开发者变量 self.ok_btn → 直接操作
```

## 三、.mui 文件格式

```json
{
  "version": 1,
  "root": {
    "type": "Panel",
    "id": "root",
    "props": {
      "anchor": [0, 0, 1, 1],
      "padding": [12, 12, 12, 12]
    },
    "children": [
      {
        "type": "Text",
        "id": "title",
        "props": {
          "text": "设置",
          "font_size": 18,
          "h": 28
        }
      }
    ]
  }
}
```

### 节点字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | string | 是 | Widget 类名（`"Panel"`, `"Button"`, `"BoxContainer"` 等） |
| `id` | string | 否 | 唯一标识，供 Runtime:find 查找。空或缺失 = 匿名节点 |
| `props` | object | 否 | 构造参数，仅存与默认值不同的字段 |
| `children` | array | 否 | 子节点列表 |

### props 字段映射

props 的 key 直接对应 Widget 构造器的 `datas` 参数：

| prop key | 对应 datas | 示例值 |
|----------|-----------|--------|
| `anchor` | `datas.anchor` | `[0, 0, 1, 1]` |
| `padding` | `datas.padding` | `[12, 12, 12, 12]` |
| `w`, `h` | `datas.w`, `datas.h` | `80`, `28` |
| `x`, `y` | `datas.x`, `datas.y` | `100`, `50` |
| `pivot` | `datas.pivot` | `[0.5, 0.5]` |
| `text` | `datas.text` | `"确定"` |
| `font_size` | `datas.font_size` | `16` |
| `text_color` | `datas.text_color` | `[1, 1, 1, 1]` |
| `bg_color` | `datas.bg_color` | `[0.2, 0.2, 0.2, 1]` |
| `orientation` | `datas.orientation` | `"vertical"` |
| `separation` | `datas.separation` | `4` |
| `alignment` | `datas.alignment` | `"begin"` |
| `h_size_flags` | `datas.h_size_flags` | `3`（FILL + EXPAND） |
| `v_size_flags` | `datas.v_size_flags` | `1`（FILL） |
| `stretch_ratio` | `datas.stretch_ratio` | `1.0` |
| `checked` | `datas.checked` | `true` |
| `h_align` | `datas.h_align` | `"center"` |
| `v_align` | `datas.v_align` | `"center"` |

## 四、MuseEditorRuntime（单例）

### 接口

```lua
local Runtime = require("ui_editor.runtime.muse_editor_runtime"):getInstance()
```

| 方法 | 说明 |
|------|------|
| `Runtime:loadMui(path)` | 加载并解析 .mui → Lua table（带缓存） |
| `Runtime:build(parent, path)` | 在 parent 下递归构建整棵树 |
| `Runtime:find(root, id)` | 深度优先搜索，按 id 返回 widget 引用 |

### 生命周期

```
Widget:new(datas)
  └─ Runtime:build(self, mui_path)
       └─ 递归 addChild，_mui_id 标记
  └─ self.title = Runtime:find(self, "title")
  └─ self:onReady()
```

### 开发者脚本模板

```lua
local Widget = require "ui.widgets.widget"
local Runtime = require("ui_editor.runtime.muse_editor_runtime"):getInstance()

local MyDialog = Class(Widget, function(self, datas)
    Widget.new(self, "MyDialog", datas)

    Runtime:build(self, "ui/my_dialog.mui")

    -- 按 id 绑定子 widget
    self.title  = Runtime:find(self, "title")
    self.ok_btn = Runtime:find(self, "ok_btn")

    self:onReady()
end)

function MyDialog:onReady()
    self.ok_btn.onClick = function()
        self.title:setText("Clicked!")
    end
end

return MyDialog
```

## 五、编辑器自身架构

编辑器本身是一个 Muse UI 应用，三面板布局：

```
┌──────────┬────────────────────────┬──────────────┐
│ Tree     │  Canvas                │  Inspector   │
│ View     │                        │              │
│          │  目标 UI (实时渲染)     │  属性编辑     │
│ ▼root    │  + 选中框 + 拖拽手柄    │              │
│  title   │                        │              │
│  ok_btn  │                        │              │
├──────────┴────────────────────────┴──────────────┤
│  工具栏: [新建] [打开] [保存] [<] [>] [导出]      │
└──────────────────────────────────────────────────┘
```

### 编辑模式事件流

```
鼠标点击 Canvas
  → Canvas.onMousePressed
    → 编辑模式：拦截，不传播给子 widget
    → 射线检测命中 widget → 标记选中
    → 未命中 → 取消选中
    → 按 Tab 在重叠 widget 间切换
```

### Canvas 模块

| 功能 | 说明 |
|------|------|
| 渲染目标 UI | 正常 addChild，走 Muse 渲染管线 |
| 选中高亮 | onPostDraw 绘制选中框（矩形 + 圆角） |
| 拖拽手柄 | 8 个（4 角 + 4 边中点），拖拽调尺寸 |
| 移动 | 拖拽选中 widget 本体调整位置 |
| 对齐吸附 | 移动/调尺寸时吸附到兄弟节点边缘（±4px） |
| 交互模式 | 按 E 临时切换到正常模式，测试按钮/输入等 |

### Inspector 模块

根据选中 widget 的 `type` 动态显示属性行。每行 = label + 对应编辑控件：

| 属性类型 | 编辑控件 |
|----------|---------|
| string（text, id） | TextInput |
| number（w, h, font_size） | TextInput + 上下箭头 |
| color（bg_color, text_color） | 色块点击弹出取色器 |
| anchor | 4 个 TextInput + 9 宫格可视化锚点按钮 |
| enum（orientation, alignment, h_align） | Dropdown |
| bool（checked） | Checkbox |
| size_flags | FILL / EXPAND / SHRINK 复选框组 |

### Tree View 模块

```
▼ Panel (root)
  ▼ BoxContainer (main_layout)
    Text (title)
    Button (ok_btn)
```

| 操作 | 方式 |
|------|------|
| 选中 | 单击节点 |
| 编辑 id | 双击节点名 → TextInput |
| 调整顺序 | 拖拽节点到目标位置 |
| 添加子节点 | 右键 → Insert |
| 删除 | 右键 → Delete 或按 Delete 键 |
| 复制/粘贴 | Ctrl+C / Ctrl+V |

### 命令模式 Undo/Redo

```lua
-- 每次变更前
local snapshot = self:_snapshotTree()  -- 拍整棵树
self._undo_stack:push(snapshot)

-- Ctrl+Z
local prev = self._undo_stack:pop()
self:_restoreTree(prev)
```

## 六、开发路线

| # | 模块 | 核心产出 | 依赖 |
|---|------|---------|------|
| 1 | Canvas + Selection | 点击选中、高亮框、拖拽手柄 | — |
| 2 | Inspector | 属性编辑面板，实时生效 | 1 |
| 3 | Tree View | 层级导航、拖拽排序 | 1 |
| 4 | mui_serializer | 导出 .mui 文件 | 2, 3 |
| 5 | lua_scaffold | 生成 .lua 骨架 | 4 |
| 6 | MuseEditorRuntime | 解析 .mui、id 绑定 | 4 |
| 7 | editor_app | 三面板布局 + 工具栏 + 完整工作流 | 1-6 |
