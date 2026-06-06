# UI 框架全面优化计划

本文档基于 [UI框架分析报告.md](UI框架分析报告.md) 的八类发现，按优先级和依赖关系编排为可执行的优化路线图。

---

## 优先级定义

| 等级 | 含义 | 触发条件 |
|------|------|----------|
| **P0** — 立即修复 | 已确认的 bug，会导致错误行为 | 颜色双重转换、cursor_blinking 共享状态 |
| **P1** — 高优先级 | 影响功能可用性或代码可维护性的核心问题 | 焦点管理缺失、容器脏标记、TextInput 功能缺失 |
| **P2** — 中优先级 | 架构改善和性能优化，在正常使用中不构成阻塞 | Transform 变更检测、容器合并、主题系统 |
| **P3** — 低优先级 | 锦上添花，长期代码健康 | 自动化测试、命名修正、接口美化 |

---

## 第一阶段：Bug 修复（P0）

本阶段解决已确认的、会导致可观测错误行为的问题。**应在任何新功能开发之前完成。**

### 1-1 修复颜色值双重转换

- **位置**: [chat_history.lua:76](ui/widgets/chat_history.lua#L76), [text.lua:112-118](ui/widgets/text.lua#L112-L118)
- **问题**: `setTextColor` 同时接受 0~1 的表和 0~255 的数值两种形式，`unpack()` 将表展开为数值后走错分支，颜色被二次除以 255。
- **修复方案**:

  方案 A（最小改动）：将 `unpack(style.text_color)` 改为直接传表，走 `type(r) == "table"` 分支。

  ```lua
  self.text:setTextColor(style.text_color or self.text.theme.text.text_color)
  ```

  方案 B（根除）：统一 `setTextColor` 接口，只接受 0~1 的表格式。全项目审计所有调用点，将 `Utils.RGB()` 返回值统一作为唯一颜色格式。废弃数字参数路径。

  建议先执行方案 A 快速止血，随后在第二阶段执行方案 B 的统一化。

- **相关文件**: `ui/widgets/text.lua`, `ui/widgets/chat_history.lua`, `ui/utils.lua`（`Utils.RGB`）
- **预估改动量**: 方案 A 一行，方案 B 约 10~20 行（含全项目调用点审计）

### 1-2 修复 cursor_blinking 模块级变量共享

- **位置**: [textinput.lua:9-10](ui/widgets/textinput.lua#L9-L10)
- **问题**: `cursor_blinking` 和 `cursor_blinking_timer` 是模块级 `local`，所有 TextInput 实例共享同一对变量。多实例场景下闪烁频率翻倍，`setCursorIndex` 会干扰其他实例的闪烁周期。
- **修复方案**: 将这两个变量移入 `self`（实例字段）。

  ```lua
  -- 构造函数中
  self._cursor_blinking = true
  self._cursor_blinking_timer = 0
  ```

- **预估改动量**: ~15 行（涉及所有引用点的 `self.` 前缀添加）

---

## 第二阶段：核心功能补全（P1）

### 2-1 焦点管理系统

- **分析报告引用**: 第 2.4 节
- **现状**: UiManager 不维护焦点 widget 记录。每个 widget 各自管理 `self.focus`，无统一的焦点作用域。
- **目标**:
  1. UiManager 维护 `current_focus` 字段，指向当前持有焦点的 widget
  2. 提供 `setFocus(widget)` / `getFocus()` / `clearFocus()` API
  3. 点击任意 widget 外部区域时自动清除焦点
  4. 支持 Tab 键在可聚焦 widget 之间切换（按树遍历顺序或 tabIndex）
  5. widget 通过 `self.focusable = true` 声明自己可被聚焦（默认 false，TextInput 等设为 true）
- **设计要点**:
  - 焦点切换时调用旧 widget 的 `onRemoveFocus()` 和新 widget 的 `onFocus()`
  - Tab 顺序默认按深度优先遍历，可选通过 `tab_index` 字段覆盖
  - 不与现有 widget 级 `self.focus` 冲突——UiManager 的焦点记录是权威来源，widget 级字段在 `onFocus`/`onRemoveFocus` 中同步
- **预估改动量**: UiManager 新增 ~60 行，Widget 基类新增 ~15 行，TextInput 适配 ~10 行

### 2-2 容器布局脏标记机制

- **分析报告引用**: 第 1.1 节、第 4.1 节
- **现状**: `list_h_container` 和 `list_v_container` 每帧无条件执行 `layout()` 做 O(n) 全量重算。
- **目标**:
  1. 引入 `self._layout_dirty` 脏标记，初始为 `true`
  2. 仅在以下操作时置脏：`addChild`、`removeChild`、容器 `transform` 尺寸变化
  3. `onUpdate` 中检查脏标记，仅当 dirty 时调用 `layout()`，然后清除标记
  4. （可选优化）`layout()` 内部增量计算：新插入元素只算自身及后续元素的偏移，而非从头遍历
- **注意**: `layout()` 修改 `self.transform` 尺寸可能反向触发 `_layout_dirty` 的循环依赖。需要在 `layout()` 内暂时屏蔽脏标记的重新设置，或使用 `_in_layout` 守卫。
- **预估改动量**: list 容器各 ~20 行，Widget.addChild/removeChild 各 ~3 行

### 2-3 TextInput 文本选区

- **分析报告引用**: 第 2.3 节
- **现状**: 光标可定位但无法选中文字。
- **目标**:
  1. 新增 `self._selection_start` 和 `self._selection_end`（光标索引）
  2. `Shift + 方向键` 扩展选区，鼠标拖拽选择
  3. 渲染时对选区范围内的文本绘制高亮背景
  4. `Ctrl+A` 全选
- **预估改动量**: ~80 行（选区状态管理 ~20，渲染 ~30，输入处理 ~30）

### 2-4 TextInput 系统剪贴板集成

- **分析报告引用**: 第 2.3 节
- **现状**: 无复制/粘贴。
- **目标**:
  1. `Ctrl+C` → 将选区文本写入 `love.system.setClipboardText()`
  2. `Ctrl+V` → 从 `love.system.getClipboardText()` 读取并在光标位置插入
  3. `Ctrl+X` → 剪切（复制 + 删除选区）
- **依赖**: 需要先完成文本选区（2-3）
- **预估改动量**: ~30 行

### 2-5 TextInput 撤销/重做

- **分析报告引用**: 第 2.3 节
- **现状**: 无操作历史。
- **目标**:
  1. 维护操作历史栈（`self._undo_stack` 和 `self._redo_stack`）
  2. 每次文本变更（插入、删除、粘贴、剪切）将反向操作推入撤销栈
  3. `Ctrl+Z` 撤销，`Ctrl+Y` 或 `Ctrl+Shift+Z` 重做
  4. 新操作清空重做栈
  5. 栈深度限制（如 100）防止内存无限增长
- **设计考量**: 操作粒度——每次按键单独记录会导致撤销一步只删一个字符，体验差。建议按"操作组"合并：连续的同类型输入合并为一个操作组，在停顿（~300ms）或光标移动/点击时提交组。
- **预估改动量**: ~100 行

---

## 第三阶段：架构改善（P2）

### 3-1 统一颜色值格式

- **分析报告引用**: 第 3.1 节根本原因
- **问题**: `setTextColor`、`Utils.RGB`、主题系统之间颜色格式不一致（0~1 的表 vs 0~255 的数值），是 bug 的温床。
- **方案**:
  1. 全局约定：所有存储的颜色值为 `{r, g, b, a}` 格式，各分量 0~1
  2. `Utils.RGB(r, g, b, a)` 保持当前行为（0~255 → 0~1 表），但标记为"仅用于字面量转换"
  3. 所有接受颜色的 setter 统一只接受表格式，废弃数字参数路径
  4. 全项目 call site 审计，确保不存在 `unpack()` 传颜色给 setter 的用法
- **预估改动量**: ~50 行（含审计）

### 3-2 SliderBar 水平/垂直版本合并

- **分析报告引用**: 第 5.1 节
- **现状**: `sliderbar_v.lua` 和 `sliderbar_h.lua` 共约 350 行，~90% 逻辑重复。
- **方案**:
  1. 创建统一的 `sliderbar.lua`，构造函数接受 `orientation` 参数（`"horizontal"` | `"vertical"`）
  2. 内部用 `self._axis` 表抽象轴向差异：

     ```lua
     -- 水平
     self._axis = { pos = "x", size = "w", min_edge = "left", max_edge = "right" }
     -- 垂直
     self._axis = { pos = "y", size = "h", min_edge = "top", max_edge = "bottom" }
     ```

  3. 保留 `sliderbar_v.lua` 和 `sliderbar_h.lua` 作为薄兼容层（require 新模块并传入 orientation），或直接废弃
- **预估改动量**: ~200 行（合并后净减少 ~150 行）

### 3-3 List 容器水平/垂直版本合并

- **分析报告引用**: 第 5.2 节
- **现状**: `list_h_container.lua` 和 `list_v_container.lua` 逻辑高度重复。
- **方案**: 与 SliderBar 合并策略相同——统一模块 + `orientation` 参数 + 轴向抽象表。
- **注意**: 合并时同时引入脏标记（2-2），避免对已 merge 的新模块做二次修改。
- **预估改动量**: ~180 行（合并后净减少 ~130 行）

### 3-4 主题系统落地

- **分析报告引用**: 第 2.5 节
- **现状**: `Theme` 类已定义，文档说明可继承定制，但从未被实际使用。所有样式差异通过 `datas` 逐个覆盖。
- **方案**:
  1. 将 `main.lua` 中的散落样式值抽取为一个或多个 Theme 子类
  2. 在 UiManager 中支持子树级默认主题——为某个 widget 子树设置默认 theme，子树内新 widget 自动继承
  3. 主题查找链：widget 自身 `datas` → widget 自身 `theme` → 父级默认 theme → UiManager 全局默认 theme
- **预估改动量**: Theme 类扩展 ~40 行，main.lua 重构 ~50 行

### 3-5 Transform 变更检测

- **分析报告引用**: 第 4.2 节
- **现状**: Transform 的 `onUpdate` 每帧无条件执行 `_updateLeftRight` / `_updateWidthAndX` 等计算。
- **方案**:
  1. 在 Transform 中缓存锚点、padding、pivot 的"上次有效值"
  2. `onUpdate` 开始时比较当前值与缓存值，全部相同时跳过计算
  3. 注意浮点比较使用 epsilon 容差
- **预估改动量**: ~30 行

### 3-6 按钮状态机组件化

- **分析报告引用**: 第 5.4 节
- **现状**: 交互状态机（六态切换）耦合在 `ButtonBase` 中，导致非按钮控件（如 SliderBar 的滑块）需要继承 Button 才能获得拖拽行为。
- **方案**:
  1. 将状态机从 `ButtonBase` 抽取为独立的行为组件 `interactive_state.lua`
  2. 组件提供：`states = { normal, hover, pressed, disabled, selected, selected_hover }`，以及状态转换规则
  3. `ButtonBase` 改为持有该组件并代理状态查询，自身只保留 click/press 回调逻辑
  4. `SliderBar` 的 block 直接使用组件而非继承 Button
  5. 注意向后兼容——Button/ImageButton 的对外 API 不变
- **预估改动量**: ~150 行（新增组件 ~80，ButtonBase 精简 ~40，SliderBar 适配 ~30）

### 3-7 Widget 构造参数统一

- **分析报告引用**: 第 6.2 节
- **现状**: 基类 `Widget(name, datas, theme)` 与子类 `Panel(datas, theme)` 签名不一致。
- **方案**:
  1. 保持子类现有签名不变——它们是面向用户的主要构造入口
  2. 将基类 Widget 的 `name` 参数改为可选（默认 `"Widget"`），使基类也支持 `Widget(datas, theme)` 调用
  3. 子类通过 `BaseClass.new(self, "FixedName", datas, theme)` 在内部提供固定 name，这是合理的设计
  4. 更新 CLAUDE.md 中的文档说明此约定
- **预估改动量**: Widget 构造函数 ~5 行

---

## 第四阶段：功能扩展（P2-P3）

### 4-1 基础 Widget 补齐

- **分析报告引用**: 第 2.1 节
- **缺失控件**: Checkbox/Toggle、RadioButton/RadioGroup、Dropdown/ComboBox、Tooltip、ProgressBar、TabView、Modal/Dialog
- **实现优先级**:

| 控件 | 理由 |
|------|------|
| Checkbox / Toggle | ButtonBase 的状态机可直接复用，六态映射到 checked/unchecked 两态加 hover/pressed |
| ProgressBar | 纯视觉组件（Panel + 填充 Panel），无交互复杂度 |
| RadioButton / RadioGroup | 依赖 Checkbox 的模式，加上组内互斥逻辑 |
| Modal / Dialog | 需要遮罩层（Panel 全屏半透明）+ 居中容器，不涉及新交互模式 |
| Tooltip | 需要跨层级渲染能力（见架构问题 7.3），建议等渲染排序机制改善后再做 |
| Dropdown / ComboBox | 需要弹出层 + 列表选择 + 点击外部关闭，复杂度最高，最后实现 |
| TabView | 中等复杂度，需要面板切换 + 标签渲染 |

- **预估改动量**: 每个控件 80~200 行不等

### 4-2 Box 容器实现

- **分析报告引用**: 第 2.2 节
- **现状**: `box_h_container.lua` 和 `box_v_container.lua` 是空文件。
- **目标**: 实现"固定容器尺寸、自动拉伸或压缩子元素"的行为（类似 Flexbox stretch）。
- **算法**:
  1. 容器有固定主轴尺寸（由 anchor + padding 决定）
  2. 子元素声明最小/首选尺寸
  3. 剩余空间按权重（`flex_grow`）分配，超出空间按收缩权重（`flex_shrink`）压缩
  4. 交叉轴方向子元素默认拉伸填充容器
- **依赖**: 需要先完成 list 容器合并（3-3），避免重复代码
- **预估改动量**: ~250 行

### 4-3 可见性裁剪

- **分析报告引用**: 第 1.3 节
- **现状**: Widget 树全量递归遍历，不做视口外裁剪。
- **方案**:
  1. 在 `Widget:update()` 和 `Widget:draw()` 中增加裁剪检查
  2. 利用已有的 `getGlobalBounds()` 获取 widget 的全局包围盒
  3. 与裁剪区域（如 ScrollContainer 的 scissor 区域或屏幕范围）做 AABB 相交检测
  4. 不相交的 widget 跳过自身及子树的 update/draw
  5. 提供 `self.always_update` / `self.always_draw` 标志位允许 widget 选择退出裁剪优化
- **注意**: `onUpdate` 跳过可能导致依赖每帧 update 做逻辑的 widget 行为异常。需要文档说明此变更，并提供迁移指引。
- **预估改动量**: Widget.update ~15 行，Widget.draw ~15 行，ScrollContainer 裁剪区域暴露 ~10 行

---

## 第五阶段：架构演进（P3）

这些改动涉及框架的顶层设计假设变更，影响面大，需要在前面阶段充分稳定后逐步推进。

### 5-1 布局系统引入 Measure 阶段

- **分析报告引用**: 第 7.1 节
- **现状**: 纯父 → 子单向布局，子元素无法向父容器声明需求尺寸。`TextInput.height_adaptive` 是局部 hack。
- **方案**:
  1. Widget 基类新增 `measure(max_width, max_height)` 方法，返回 `{min_w, min_h, pref_w, pref_h}`
  2. 容器在 `layout()` 之前先对所有子元素调用 `measure()`，收集需求
  3. 容器根据子元素需求和自身策略（锚点约束 / flex 分配）决定最终尺寸分配
  4. 默认 `measure()` 返回当前 transform 尺寸作为固定需求，保持向后兼容
  5. Text、TextInput 等覆盖 `measure()` 返回基于内容的实际需求
- **影响分析**: 这是全框架最深层级的变更，涉及所有容器和内容 widget 的布局逻辑。需要先完成容器合并（3-3）和 Box 容器（4-2），在统一的容器基类上实施。
- **预估改动量**: ~400 行

### 5-2 渲染层与逻辑层分离

- **分析报告引用**: 第 7.3 节
- **现状**: 渲染顺序完全绑定树结构。跨层级渲染（Tooltip、Modal 遮罩、Dropdown 弹出层）需要将元素脱离逻辑父节点挂在根下。
- **方案**:
  1. 引入"渲染层"概念：每个 widget 可选声明所属的渲染层（整数，默认 0）
  2. 绘制时按渲染层分组：先绘制层 0 的所有 widget，再绘制层 1 的所有 widget，以此类推
  3. 同一层内按树结构自然顺序绘制
  4. 遮罩层（层 99）、Tooltip（层 100）等预定义层常量
  5. 树的逻辑结构不受影响——Tooltip 逻辑上仍属于触发它的按钮，只是渲染时提升到更高层
- **方案替代**: 如果不想改动遍历机制，可以保留当前"手动挂根"模式，但由 UiManager 提供 `addOverlay(widget, layer)` API 自动处理根的挂载和渲染顺序。
- **预估改动量**: ~150 行

### 5-3 全局 Class 解耦

- **分析报告引用**: 第 7.5 节
- **现状**: `Class` 是全局变量，`ui/` 下所有模块直接引用。框架与应用的加载顺序存在隐式依赖。
- **方案**:
  1. 在每个 `ui/` 模块顶部添加 `local Class = require "dependencies.classic"`（取代全局引用）
  2. 保持 `main.lua` 中的 `Class = require ...` 不变直到所有模块迁移完毕
  3. 最终可选将全局赋值改为仅在 main.lua 中使用
- **注意**: 这是纯机械性修改，但涉及 ~25 个文件。建议分批次、在低变更期进行以减小合并冲突。
- **预估改动量**: ~25 行（每个文件一行，净增 require 行数）

### 5-4 UI 上下文隔离

- **分析报告引用**: 第 7.2 节
- **现状**: UiManager 全局单例，无法创建独立的 UI 上下文。
- **方案**:
  1. UiManager 从单例模式改为可实例化类
  2. 每个 UiManager 实例持有独立的 hierarchy、默认主题、焦点状态
  3. 保留 `GetInstance()` 返回默认实例以保持向后兼容
  4. 对于需要多视口或多 UI 上下文的场景，创建额外的 UiManager 实例
  5. Widget 构造时接受 `ui_manager` 参数指定所属上下文，默认使用全局实例
- **预估改动量**: ~100 行

---

## 第六阶段：质量基础设施（P3）

### 6-1 自动化测试框架搭建

- **分析报告引用**: 第 8.1 节
- **现状**: 零测试。
- **方案**:
  1. 选择测试框架：LÖVE 社区有 `busted` + `luassert` 组合，或使用 `luaunit`
  2. **优先测试 Transform**：它是纯计算模块，无渲染依赖，收益最高。测试覆盖锚点计算、padding ↔ 尺寸/位置的双向转换、全局坐标链、旋转 AABB
  3. 其次测试 Theme 合并逻辑、Widget 树操作（addChild/removeChild 循环引用检测）
  4. 引入简单 CI（GitHub Actions 运行 `love . --test` 或直接 `lua` 运行测试套件）
- **预估改动量**: 测试框架配置 ~20 行，Transform 测试 ~200 行

### 6-2 拼写与命名修正

- **分析报告引用**: 第 6.4 节、第 6.5 节
- **修正项**:

| 位置 | 当前 | 修正 |
|------|------|------|
| `collapsible_h_screen_edge_panel.lua:8` | `CpllapsibleHScreenEdgePanel` | `CollapsibleHScreenEdgePanel` |
| `sliderbar_v.lua:92` | `setBlockLengthtPercent` | `setBlockLengthPercent` |
| `sliderbar_h.lua:92` | `setBlockLengthtPercent` | `setBlockLengthPercent` |

- **注意**: 方法名修正是**破坏性变更**——外部调用方需要同步更新。先搜索全项目确认所有调用点。
- **预估改动量**: ~6 行

### 6-3 未使用变量清理

- **分析报告引用**: 第 6.3 节
- **现状**: `main.lua:18` 的 `Scroll` 变量未被引用，仅保留 require 的副作用。
- **方案**: 删除该行。`ChatHistory` 内部已独立 require `scroll_container`。
- **预估改动量**: 1 行

### 6-4 `newButtonStateStyle` 接口改为传表

- **分析报告引用**: 第 6.1 节
- **现状**: 9 个位置参数，大部分调用只传 1~2 个。
- **方案**:
  1. 改为 `Utils.newButtonStateStyle(datas)`，接受一个表
  2. 对所有调用点执行迁移（`newButtonStateStyle("Normal")` → `newButtonStateStyle({text = "Normal"})`）
  3. 新接口同时接受旧的位置参数调用并打印 deprecation 警告，为过渡期留时间
- **预估改动量**: ~30 行

---

## 执行顺序总览

```
第一阶段 (P0)
├── 1-1 颜色双重转换修复
└── 1-2 cursor_blinking 实例化

第二阶段 (P1)
├── 2-1 焦点管理系统
├── 2-2 容器布局脏标记
├── 2-3 文本选区
├── 2-4 剪贴板集成      ← 依赖 2-3
└── 2-5 撤销/重做       ← 依赖 2-3, 2-4

第三阶段 (P2)
├── 3-1 统一颜色格式
├── 3-2 SliderBar 合并
├── 3-3 List 容器合并   ← 与 2-2 同时做，避免二次改动
├── 3-4 主题系统落地
├── 3-5 Transform 变更检测
├── 3-6 按钮状态机组件化
└── 3-7 Widget 构造参数统一

第四阶段 (P2-P3)
├── 4-1 基础 Widget 补齐
├── 4-2 Box 容器          ← 依赖 3-3
└── 4-3 可见性裁剪

第五阶段 (P3)
├── 5-1 Measure 阶段      ← 依赖 3-3, 4-2
├── 5-2 渲染层分离
├── 5-3 Class 解耦
└── 5-4 UI 上下文隔离

第六阶段 (P3)
├── 6-1 自动化测试
├── 6-2 拼写修正
├── 6-3 未使用变量清理
└── 6-4 接口美化
```

---

## 工作量估算

| 阶段 | 预估总行数变动 | 破坏性变更 |
|------|---------------|------------|
| 第一阶段 | ~30 | 无 |
| 第二阶段 | ~280 | 无（新增 API） |
| 第三阶段 | ~650（含净删除 ~280） | 无 |
| 第四阶段 | ~700 | 可见性裁剪可能影响依赖每帧 update 的 widget |
| 第五阶段 | ~675 | Measure 阶段影响所有容器子类 |
| 第六阶段 | ~260 | 方法名拼写修正 |

**总计**: 约 2600 行变动（含新增、修改、删除），其中净增约 1800 行。

---

## 执行状态记录

### ✅ 第一阶段：Bug 修复（P0）— 已完成

- **1-1 颜色双重转换**：先止血（方案 A），后根除（方案 B，统一 `setTextColor` 只接受表格式）
- **1-2 cursor_blinking**：已移至 `self._cursor_blinking` / `self._cursor_blinking_timer`

### ✅ 第二阶段：核心功能补全（P1）— 已完成

- **2-1 焦点管理**：`UiManager.current_focus` + `setFocus/getFocus/clearFocus` + Tab/Shift+Tab 切换 + Widget.focusable
- **2-2 脏标记**：`_layout_dirty` + `_in_layout` 守卫，`onUpdate` 检测后触发 `layout()`
- **2-3 文本选区**：Shift+方向键 + 鼠标拖拽 + 高亮渲染（含跨 section 选区修正）
- **2-4 剪贴板**：Ctrl+C/V/X 集成 `love.system`
- **2-5 撤销/重做**：操作栈 + 类型合并 + 300ms 非活动计时器自动提交操作组

### ✅ 第三阶段：架构改善（P2）— 已完成

- **3-1 颜色格式统一**：已在 P0 方案 B 顺带完成
- **3-2 SliderBar 合并**：统一 `sliderbar.lua`，AXIS 轴向抽象，薄兼容层保留
- **3-3 List 容器合并**：统一 `list_container.lua`，同时合并了 2-2 脏标记逻辑
- **3-4 主题系统落地**：Theme 新增 sliderbar/progressbar/checkbox/radiobutton/modal/tabview 条目，瑞士现代主义默认主题
- **3-5 Transform 变更检测**：16 字段缓存比较，跳过无变更帧
- **3-6 按钮状态机去重**：`components.lua` 新增 `applyButtonTextStyle` + `applyButtonTransform`
- **3-7 Widget 构造参数统一**：name 改为可选，支持 `Widget(datas, theme)` 调用

### ✅ 第四阶段：功能扩展（P2-P3）— 已完成

- **4-1 基础 Widget 补齐**：
  - ✅ ProgressBar（纯视觉，支持水平/垂直）
  - ✅ Checkbox（继承 ButtonBase 六态 FSM，支持 checkbox/toggle 样式，`self._checked` 逻辑状态追踪）
  - ✅ RadioButton（继承 Checkbox，圆形渲染）+ RadioGroup（互斥管理 + `_handling` 级联守卫）
  - ✅ Modal（全屏遮罩+居中内容，移除冗余 `_is_showing` 直接复用 Widget.shown，遮罩事件拦截，anchor={0,0,1,1} 窗口自适应）
  - ✅ TabView（Tab 栏+内容面板切换）
  - ⏭ Tooltip / Dropdown（跳过，依赖第五阶段渲染层分离）
- **4-2 Box 容器**：Flexbox 布局（flex_grow/flex_shrink + cross_align），薄包装层
- **4-3 可见性裁剪**：Widget:draw() 内 AABB intersect 检查 + ScrollContainer `_clip_rect` 传播 + `always_draw` 逃逸

### 🔧 实施中发现并修复的额外 Bug

| Bug | 根因 | 修复 |
|-----|------|------|
| Transform `setPadding` 覆盖点锚点 w/h | `_updateHeightAndY` 对 `anchor_h==0` 计算 `h = -top - bottom` | `_updateWidthAndX`/`_updateHeightAndY` 内部检查 `anchor_w>0`/`anchor_h>0`，点锚点时仅更新位置不碰尺寸 |
| Transform `setAnchor` 锚点模式不一致 | 始终调点锚点函数 `_updateLeftRight`，对拉伸锚点初始化的 padding 值错误（基于 screen 尺寸） | `setAnchor` 按锚点模式分发：点锚点→`_updateLeftRight`，拉伸→`_updateWidthAndX` |
| ScrollContainer 按钮事件穿透 | stretch anchor widget 构造时无父级，padding 被 screen 尺寸污染，宽度覆盖整屏 | Gallery 按钮改用点锚点+显式宽度 |
| Modal Close 按钮失效 | Modal 构造函数未设 anchor（默认点锚点 w=0,h=0），遮罩从 0 父级推算尺寸为 0，`content_container`(w=0,h=0) 的 `regionDetection` 永远 false | Modal 构造注入 `anchor={0,0,1,1}`，遮罩点击检测改用实际内容子元素 |
| Modal `_is_showing` 与 `shown` 不同步 | `_is_showing` 是冗余 flag，初始 hide() 因 `_is_showing=false` 提前返回，`shown=true` 未修正，弹窗构造即可见但 dismiss 永远无效 | 删除 `_is_showing`，统一用 `self.shown` |
| Checkbox 无法取消选中 | `isChecked()` 依赖 `cur_state`，PRESSED 状态下返回 false，`toggle()` 永远选中 | 独立 `self._checked` 逻辑状态字段 |
| Checkbox `onChecked` 触发两次 | `setChecked` 和 `setSelected` 各调一次 | 删除 `setChecked` 中重复调用 |
| RadioGroup 点击新选项无法选中 | `setChecked(false)` 触发 `onChecked` 回调 → 级联 mutual deselection | `_handling` 重入守卫 |
| TextInput 键盘事件泄漏 | `onKeyPressed` 缺 `isFocus()` 守卫，所有实例响应 | 加焦点检查 |
| UiManager 事件分发无 break | 所有根 widget 全部接收事件，Modal 遮罩无法拦截 | 各事件循环加 `if handled then break` |
| ListContainer 子元素尺寸变化无 re-layout | 仅 `addChild/removeChild` 置脏，子元素自适应高度变化不触发 | `onUpdate` 新增子元素尺寸变更检测 |

### 📐 新增 / 改进

- **测试场景重构**：从单体 main.lua 改为 Gallery 浏览器（`tests/gallery.lua` + `tests/ui/` 9 个独立测试脚本），左侧滚动列表 + 右侧展示画布
- **瑞士现代主义默认主题**：高对比度灰阶 + 钢蓝强调色 + 4px 圆角 + 1px 描边
- **CLAUDE.md 更新**：Widget 继承树、Transform 锚点模式陷阱、Gallery 测试模式、闭包前向引用
