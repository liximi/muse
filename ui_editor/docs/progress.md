# Muse UI Editor — 开发进度

## 启动方式
```bash
love .          # 默认进编辑器
love . gallery  # Gallery 测试工具
```

## 已完成

### 编辑器核心
| 模块 | 文件 | 功能 |
|------|------|------|
| Canvas | `editor/canvas.lua` | 设计画布：编辑/交互双模式，transform 命中检测，拖拽移动 + 手柄缩放 + 锚点可视化，onBeforeModify 回调 |
| Selection | `editor/selection.lua` | 选中框 + 8 拖拽手柄，使用 `transform:getGlobalAABB()` 取布局包围盒 |
| Inspector | `editor/inspector.lua` | 属性面板：w/h/anchor/padding 动态行，数字校验，失焦提交，onBeforePropertyChange 回调 |
| TreeView | `editor/tree_view.lua` | 层级树：程序化三角形图标，Button SELECTED 状态驱动选中高亮，增量刷新，双轴滚动，深色背景，右键删除 |
| Toolbar | `editor/toolbar.lua` | 底部工具栏：New / Open / Save / Export / Undo / Redo |
| UndoManager | `editor/undo_manager.lua` | 快照式撤销/重做：捕获 transform 真相源 + 关键属性，最大深度 50 |
| EditorApp | `editor/editor_app.lua` | 四面板布局 + 演示 UI + 全模块连线，零 monkey-patch |

### 序列化 & 运行时
| 模块 | 文件 | 功能 |
|------|------|------|
| mui_serializer | `editor/mui_serializer.lua` | Widget 树 → .mui JSON 导出，默认值省略，类型映射（HBox→BoxContainer+orientation） |
| lua_scaffold | `editor/lua_scaffold.lua` | .lua 骨架生成：Class → Runtime:build → find 绑定 → onReady |
| MuseEditorRuntime | `runtime/muse_editor_runtime.lua` | 单例，loadMui/build/findOf，类型注册表 15+ 种 |
| JSON | `runtime/json.lua` | 编解码器，serializer 和 Runtime 共用 |

### 共享数据
| 模块 | 文件 | 功能 |
|------|------|------|
| widget_meta | `editor/widget_meta.lua` | LEAF_TYPES 叶子类型表（serializer / Canvas / TreeView / EditorApp 共用） |
| widget_palette | `editor/widget_palette.lua` | Widget 类型面板：14 种类型按钮 + 工厂函数 `createWidget(type)` |

### 框架修复
- `textinput.lua`: `_deleteSelection` 双段 bug（removeSection 自动 appendNewSection → 多余 `\n`）
- `textinput.lua`: `onTextInput` 单行模式下过滤 `\r?\n`
- `textinput.lua`: onHovered 判空 self.bg
- `textinput.lua`: 光标 + 选区绘制跟随 v_align 垂直偏移
- `canvas.lua`: 增加 scissor 裁剪 + 画布背景色 + 边框，防止子控件绘制溢出到侧边栏/工具栏
- `canvas.lua`: `onDraw` 设 `_clip_rect` 传播给子节点做 culling 优化

### 已知限制
- **撤销不支持结构变更**：快照式 UndoManager 只记录现有 widget 属性，addChild/removeChild 后撤销可能错位。需升级为命令模式。

---

## 待开发

### P0 — 核心编辑能力 ✅ 已完成（2026-07-16）
| # | 功能 | 状态 |
|---|------|------|
| 1 | **Canvas 拖拽移动** | ✅ `canvas.lua` — screenToLocal 坐标转换，`onBeforeModify` 回调驱动撤销 |
| 2 | **手柄缩放** | ✅ 拖拽 8 手柄调 w/h，min size=10 约束，pivot 感知；Selection 改用 `transform:getGlobalAABB()` 防 Text 内容尺寸错位 |
| 3 | **添加/删除 widget** | ✅ 右键 TreeView 节点→删除；Delete 键删除；Palette 点击创建；任意控件都可作父容器（`_mui_type` 区分用户/内部子节点） |
| 4 | **Widget 类型面板** | ✅ `widget_palette.lua`：14 种 Canvas 渲染图标、左对齐文字、hover 高亮、自动偏移防重叠 |
| - | **锚点可视化** | ✅ 选中 widget 显示青色锚点（点/拉伸）+ 金色 pivot 点 |
| - | **TreeView 横向滚动** | ✅ 根据嵌套深度自动扩宽内容 + Scroll 双轴滚动 |
| - | **布局修正** | ✅ 拉伸锚点面板 bottom padding 正数化，不再溢出窗口 |

### P1 — 属性编辑完善 ✅ 已完成（2026-07-17）
| # | 功能 | 状态 |
|---|------|------|
| 5 | **文本属性** | ✅ text、font_size、text_color、h_align、v_align |
| 6 | **颜色属性** | ✅ bg_color / outline_color / text_color 色块 + RGBA 0-255 数字输入 |
| 7 | **枚举属性** | ✅ orientation / alignment / h_align / v_align / size_flags → Dropdown |
| 8 | **容器属性** | ✅ separation / orientation / alignment / auto_size / stretch_ratio |
| - | **属性分组** | ✅ 布局 / 容器标志 / 外观 / 文本 / 容器 分区标题 |
| - | **类型感知** | ✅ Inspector 根据 `_mui_type` 动态展示对应属性组 |
| - | **布尔属性** | ✅ Checkbox 行（auto_size、single_line、checked） |

**实现细节**：
- `makeColorRow` — 标签 + 色块 + R/G/B/A 4 个 TextInput（0-255），失焦自动同步
- `makeDropdownRow` — 使用 Dropdown 组件，修复了 `self:onSelect` 冒号语法导致的参数偏移（`_self, idx, val`）
- `makeCheckboxRow` — 行级点击切换，Checkbox 仅作视觉指示（raycast_target=false）
- `isInsideContainer` — 检测父节点是否有 `_sortChildren`，动态显示 size_flags 行
- Button 属性走 `state_styles.normal` + `setState()` 刷新，所有 getter nil-safe

**代码拆分**（2026-07-17）：
- `inspector.lua` → ~140 行（类定义 + onUpdate 同步）
- `inspector/rows.lua` → ~380 行（行工厂：文本/颜色/Dropdown/Checkbox/分区标题）
- `inspector/fields.lua` → ~380 行（`populateFields` — 按 `_mui_type` 分发 §1~§6 属性段）

### P2 — 工作流完善
| # | 功能 | 说明 |
|---|------|------|
| 9 | **文件对话框** | 新建（输入类名）/ 打开（浏览 .mui）/ 另存为 |
| 10 | **multi-widget 支持** | 编辑器不限于单一 demo UI，可创建任意类型根节点 |
| 11 | **键盘快捷键完善** | Delete 键删除、方向键微调位置 |
| 12 | **撤销粒度** | Inspector 每次 setter 调前自动 pushSnapshot（已实现 onChange 回调，需连线） |

### P3 — 体验优化
| # | 功能 | 说明 |
|---|------|------|
| 13 | **画布网格/吸附** | 移动/缩放时吸附到网格或兄弟节点边缘 |
| 14 | **多选** | Shift/Ctrl 多选，批量属性编辑 |
| 15 | **TreeView 拖拽排序** | 拖拽节点调整层级/顺序 |
| 16 | **TreeView 展开/折叠** | 点击三角形折叠子树 |

