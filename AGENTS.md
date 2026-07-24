# AGENTS.md

Muse UI 框架的 AI 编程指南。覆盖架构、容器系统、编码规范和常见陷阱。

## 项目概述

**Muse** — 基于 LÖVE (Love2D) 游戏引擎的 UI 框架，使用 **LuaJIT**（Lua 5.1 + 扩展）编写。布局系统已从 Unity UGUI 锚点路线转向 **Godot Container 路线**（2026-07 重构）。

## 运行

```
love .          # LÖVE 11.5
```
浏览器 `127.0.0.1:8000` → Lovebird 远程调试。

---

## 架构

### 类系统

`dependencies/classic.lua` — `Class(BaseClass, function(self, ...) end)`。`main.lua` 全局化 `Class`。

### 核心系统

**UiManager** (`ui/ui_manager.lua`) — 单例。持有 `hierarchy` 根节点列表，分发 LÖVE 事件。事件从末尾向前遍历。渲染层缓存 + 生命周期管理（`onAttached`/`onDetached`）。

**Widget** (`ui/widgets/widget.lua`) — 基类。Transform 实例 + 树形结构 + 生命周期钩子 + 事件传播（子节点先处理，返回 `true` 拦截）。

**Transform** (`ui/transform.lua`) — padding 是唯一真相源。所有 setter 最终写 padding，`_recalcLayout` 派生 x/y/w/h 缓存。

### 布局系统 — Godot Container 路线（2026-07 重构）

#### 设计哲学

- **子控件投降**：进入 Container 的子控件放弃自主定位权，由容器 `_sortChildren()` 统一管理
- **声明式布局**：容器套容器，每层只管一个维度
- **SizeFlags**：子控件通过位标志表达布局意图（FILL / EXPAND / SHRINK）
- **事件驱动重排**：addChild/removeChild → `queueSort()` → 下一帧 `_preChildrenUpdate` 自动重排

#### 容器继承体系

```
Widget
  └── Container (新增基类)
        ├── BoxContainer (orientation="horizontal"/"vertical")
        ├── MarginContainer
        ├── CenterContainer
        ├── Spacer (不可见弹性占位)
        ├── ListContainer (线性 + key-based diff 复用)
        └── VirtualList (虚拟化列表，仅实例化可见元素)
```

#### Container 基类 (`ui/widgets/containers/container.lua`)

核心方法：
- `queueSort()` — 标记脏，下一帧自动重排
- `_sortChildren()` — 子类覆写，实现具体布局算法
- `fitChildInRect(child, x, y, w, h)` — 按 child 的 size_flags 决定 Fill/Shrink
- `_preChildrenUpdate(dt)` — Widget.update 的钩子，在子控件 update 之前排序
- `getMinimumSize()` — 子类覆写，报告容器最小尺寸（BoxContainer 含 `math.max(children, container_size)` 保底）
- `_getChildrenMinSize()` — 纯子控件推导的最小尺寸（不经容器尺寸 cap），**供变化检测用**
- `auto_size` — 开启后在主轴方向自动调整尺寸（HBox→宽，VBox→高）

**变化检测**：`_preChildrenUpdate` 用 `_getChildrenMinSize()` 而非 `getMinimumSize()` 判断是否需要重排。
原因：BoxContainer 的 `getMinimumSize()` 返回 `math.max(children_sum, container_size)`，当容器被 anchor 撑大时，
子控件高度增长会被容器自身尺寸"盖住"，导致变化检测失败。`_getChildrenMinSize()` 返回纯子控件值，不受此影响。

**注意**：Container 覆写了 `_preChildrenUpdate` 而非 `onUpdate`。排序发生在子控件 update 之前，确保子控件同帧拿到容器分配的尺寸。

#### BoxContainer (`ui/widgets/containers/box_container.lua`)

三趟分配算法（对照 Godot `box_container.cpp _resort`）：

```
第一趟: 收集每个孩子的 min_size / desired_size / EXPAND 标记
第二趟 A: 按 desired_size 比例分配（"我需要这么多"）
    - stretch 孩子 → 提高 min，防止被 stretch 缩回去
    - 非 stretch 孩子 → 从 stretch 池扣除
第二趟 B: 按 stretch_ratio 比例分配剩余（"我贪婪"）
    - 装不下的从池中移除 → 重新分配
    - 浮点误差累积，最后一个 EXPAND 孩子吸收
第三趟: fitChildInRect 逐个定位 + alignment 偏移
```

参数：
- `orientation` — `ORIENT.HORIZONTAL` / `ORIENT.VERTICAL`（默认）
- `separation` — 间距
- `alignment` — `ALIGN.BEGIN` / `ALIGN.CENTER` / `ALIGN.END`（无 EXPAND 时生效）
- `auto_size` — 主轴自动尺寸

方法：`addSpacer()` — 添加弹性占位符（对标 Godot）。

#### SizeFlags（`Utils.SIZE_FLAGS`）

| 标志 | 值 | 含义 |
|------|-----|------|
| `SHRINK_BEGIN` | 0 | 保持最小尺寸，靠左/上（默认值 0） |
| `FILL` | 1 | 填满分到的区域（**默认每个 widget 都有**） |
| `EXPAND` | 2 | 参与剩余空间瓜分 |
| `SHRINK_CENTER` | 4 | 分到区域内居中（需关闭 FILL） |
| `SHRINK_END` | 8 | 分到区域内靠右/下（需关闭 FILL） |

每个 Widget 持有 `h_size_flags`、`v_size_flags`（默认 `FILL`）和 `stretch_ratio`（默认 1.0）。

**位检测**：`Utils.hasFlag(flags, flag)`。

#### 其他容器

- **MarginContainer** — 四边距。最简单的容器：自身尺寸减 margin → fitChildInRect
- **CenterContainer** — 子控件居中
- **Spacer** — 不可见 EXPAND+FILL Widget，射线穿透。用法：`hbox:addChild(Spacer())` 推右
- **ListContainer** — 继承 BoxContainer，默认 auto_size=true、separation=8。核心特性：`updateItems(data, keyFn, createFn, updateFn)` 基于 key 做 diff，复用已有控件、创建新控件、移除多余的旧控件。另有 `insert`/`remove`/`removeAtPos`/`setItems` 便捷方法

#### VirtualList 虚拟化列表 (`ui/widgets/containers/virtual_list.lua`)

仅实例化可见范围内的元素。适用于大数据量列表（数百～数千项），每个 item 固定尺寸。

**模板系统**：
- `VirtualListItem` (`ui/widgets/virtual_list_item.lua`) — item 基类
  - 子类必须覆写 `getItemSize() → along_size`（沿主轴固定尺寸）
  - 子类必须覆写 `bindData(data, index)`（填充数据，data 可能为 nil）

**核心算法**：
```
visibleCount  = ceil(viewport / itemStride)      -- itemStride = itemSize + separation
instanceCount = visibleCount + 2                   -- 上下各 1 个缓冲

firstIndex    = floor(scrollOffset / itemStride)
visualOffset  = -(scrollOffset % itemStride)

每个 item widget 固定布局位置 = index * itemStride
实际位置 = 固定位置 + visualOffset  ← 模拟滚动
显示数据 = getData(firstIndex + index)
```

- 实例数量仅在容器尺寸或模板尺寸变化时重建
- `firstIndex` 变化时 → 全部 item `bindData` 重绑
- 内置 wheel 事件 + scissor 裁剪 + 滚动条（支持拖拽/点击跳转）

**公开方法**：
- `setData(count, getData(index) → data)` — 设置数据源
- `scrollTo(offset)` — 设置滚动偏移（自动 clamp）
- `getScrollOffset()` / `getMaxScroll()` — 滚动状态查询
- `getItems()` — 返回当前 item 控件列表

**陷阱**：
- VirtualList 覆写了 `_getChildrenMinSize()` 返回 (0,0)，不参与 BoxContainer 的自动尺寸计算。需通过 anchor 或显式 setSize 指定尺寸
- `_sortChildren` 遍历 `self._itemWidgets` 而非 `_visibleChildren()`，确保隐藏的缓冲 item 保持正确位置
- 模板 `getItemSize()` 只能返回固定值，不支持动态尺寸 item

#### 最小尺寸系统

每个 Widget 必须能报告最小自然尺寸，容器据此分配空间：

```lua
Widget:getMinimumSize()           -- 虚方法，返回 (0,0)，子类覆写
Widget:getCombinedMinimumSize()   -- max(getMinimumSize(), custom_minimum)
Widget:setCustomMinimumSize(w, h) -- 覆盖最小尺寸
Widget:getDesiredSize()           -- 期望尺寸，默认等于 min。Text 覆写为完整文本宽度
```

已覆写 `getMinimumSize` 的控件：Text、Button、Image、ProgressBar、Scroll、BoxContainer、ChatBubble。

**重要**：普通 Widget 设了 `h = 40` 但不覆写 `getMinimumSize`，容器会分配 0 高度。需通过 datas 传 `custom_minimum_size = {nil, 40}`，或调用 `setCustomMinimumSize(nil, 40)`，或覆写 `getMinimumSize`。

#### Widget 更新生命周期（2026-07 改动）

```lua
function Widget:update(dt, parent_should_update)
    self.transform:onUpdate()        -- 1. Transform 脏检测
    -- SizeChanged 事件检测
    self:_preChildrenUpdate(dt)      -- 2. ★ 钩子（Container 在此排序）
    for child in children do         -- 3. 子控件 update
        child:update(dt, true)
    end
    self:onUpdate(dt)                -- 4. 自身 update
end
```

Container 只覆写 `_preChildrenUpdate`，不覆写 `update`。这确保了排序发生在子控件拿尺寸之前。

---

### Scroll (`ui/widgets/containers/scroll_container.lua`)

- scissor 裁剪由 `scroll_root.onDraw/onPostDraw` **闭包**管理（不要移到 Scroll.onDraw——会导致 Dropdown 内部 Scroll 内容不可见）
- **auto_track**：默认开启，onUpdate 自动检测 `item` 尺寸变化 → 更新 `scrollable_h/w` + 滑块
- **wheel 事件**：`onWheelMoved` 返回 `true` 拦截冒泡（嵌套 Scroll 各自独立滚动）
- **WheelMoved 坐标**：scroll_root.handleEvent 对 WheelMoved 使用 `love.mouse.getPosition()` 而非事件参数
- `getMinimumSize()` 返回自身 transform 尺寸

### TextInput (`ui/widgets/textinput.lua`)

- **多行模式**（默认）：固定高度 + 内部垂直滚动。`singe_line = true` 切到单行+水平滚动
- **`height_adaptive`**（opt-in，默认 false）：随文本内容自动撑高。注意此模式下 FILL 会与自适应冲突
- **滚动原理**：通过调整内部 `Text` 子控件的 `padding.top/bottom` 偏移文本内容，配合 `onDraw` 的 scissor 裁剪实现
- **光标跟随**：`_updateScrollY` 每帧检测光标是否超出可见区域，自动调整 `_scroll_y`
- **鼠标滚轮**：`onWheelMoved`，每次 3 行，仅当鼠标在区域内且有焦点；返回 `true` 防冒泡
- **原生滚动条**：`_drawScrollbar` 在 `onPostDraw` 绘制 6px 宽滚动条（轨道+比例滑块），仅在内容溢出时显示；支持拖拽滑块和点击轨道跳转
- **`getMinimumSize()`**：`height_adaptive` 时返回当前 transform 尺寸；否则返回 `min_height` + padding

### 枚举常量（`ui/utils.lua`）

| 常量表 | 值 | 用途 |
|--------|-----|------|
| `ORIENTATION` | `VERTICAL`, `HORIZONTAL` | BoxContainer, SliderBar, ProgressBar |
| `SIZE_FLAGS` | `SHRINK_BEGIN=0, FILL=1, EXPAND=2, SHRINK_CENTER=4, SHRINK_END=8` | 容器子控件布局意图 |
| `ALIGNMENT` | `BEGIN, CENTER, END` | BoxContainer alignment |
| `H_ALIGN` | `LEFT, CENTER, RIGHT, JUSTIFY` | Text, TextInput |
| `V_ALIGN` | `TOP, CENTER, BOTTOM` | Text, TextInput |
| `CROSS_ALIGN` | `STRETCH, START, CENTER, END` | 旧 Box（逐步废弃） |
| `CHECKBOX_STYLE` | `CHECKBOX, TOGGLE` | Checkbox |
| `BTN_STATES` | `NORMAL, PRESSED, DISABLED, SELECTED, HOVER, SELECTED_HOVER` | ButtonBase |
| `TEXT_WRAP_MODE` | `OFF, DEFAULT` | Text, TextInput |

工具函数：`Utils.validateEnum(value, enum, default, label)` — nil 时静默返回默认值，非法值打印警告。`Utils.hasFlag(flags, flag)` — 位检测。

### Widget 继承体系

```
Widget
├── Panel
├── Text
├── Image
├── NineSlice
├── ProgressBar
├── Modal
├── TabView
├── RadioGroup
├── ButtonBase
│   ├── Button
│   ├── ImageButton
│   └── Checkbox → RadioButton
├── TextInput
├── Scroll
├── SliderBar
├── Dropdown
├── Spacer
├── VirtualListItem (模板基类)
│   └── (用户自定义子类)
└── Container
    ├── BoxContainer
    │   └── ListContainer (diff 复用)
    ├── MarginContainer
    ├── CenterContainer
    └── VirtualList (虚拟化)
```

旧 `Box`（flex-grow/shrink）仍保留但逐步废弃。

### Button 文字与样式分离（2026-07 重构）

- **`text` 不再是样式的一部分**。`getStateStyle` 合并时跳过 `text` 字段
- `applyButtonTextStyle` 不再调用 `setText`。状态切换只改颜色/字号
- `setStateStyle(state, style)` 中若 `style.text` 存在，自动调用 `setText(style.text)`（兼容旧用法）
- 按钮文字通过 `Button({ text = "..." })` 或 `button:setText("...")` 管理
- Dropdown 触发按钮文字更新依赖 `setStateStyle` 的自动 `setText` 行为

---

## 编码规范

### 缩进：Tab

### 命名

| 对象 | 风格 | 示例 |
|------|------|------|
| 局部变量、函数参数 | `snake_case` | `ui_root`, `font_key` |
| 类内部字段 | `snake_case` | `self.bg_color` |
| 类方法 | `camelCase` | `addWidget`, `getGlobalPosition` |
| 类名 | `PascalCase` | `Widget`, `BoxContainer` |
| 常量、枚举 | `UPPER_CASE` | `SIZE_FLAGS`, `DEFAULT_BAR_HEIGHT` |
| Lua 文件名 | `snake_case` | `box_container.lua` |
| 私有成员/函数 | `_` 前缀 | `self._dirty`, `_recalcLayout` |
| 元属性 | `__` 前缀 | `self.__text`, `__oldw` |

闭包内内外 `self` 冲突时，内层参数命名为 `_self`。

### 模块结构

```lua
-- 1. require
-- 2. 私有函数/伪常量
-- 3. 类定义
-- 4. 公有方法（按功能分隔）
-- 5. 事件处理器（onXxx）
-- 6. return
```

### datas 文档块

每个 widget 文件头部 `--[[datas: ...]]` 描述构造参数。

---

## 常见陷阱

### Container / 布局

- **普通 Widget 在容器里需要 `setCustomMinimumSize`**：设了 `h=40` 但不覆写 `getMinimumSize` → 容器给 0 高度
- **auto_size 只改主轴**：VBox 只自动高度，HBox 只自动宽度。交叉轴由 parent 或 anchor 决定
- **`_preChildrenUpdate` 而非 `onUpdate`**：排序必须在子控件 update 之前
- **Scroll 内 VBox 需要 `anchor = {0,0,1,0}`**：填充 scroll_root 的宽度
- **BoxContainer.getMinimumSize() 含 `math.max(children, container_size)`**：被 anchor 撑大时子控件变化可能被掩盖；做变化检测用 `_getChildrenMinSize()`
- **子控件尺寸变化不会自动通知父容器**：依赖 `_preChildrenUpdate` 每帧 poll `_getChildrenMinSize()` 来检测

### Scroll

- **scissor 在 scroll_root 闭包，不在 Scroll.onDraw**
- **wheel 返回 true**，防止冒泡到外层 Scroll
- **raycast_target fallback 不含 WheelMoved**：滚轮穿透到可滚动父容器

### Transform

- `setSize` 对拉伸锚点不保持 x 不变
- 构造期 `parent_w == 0`，依赖 measure 的布局放首帧 onUpdate
- Text 的 `transform.w/h` 为 0，`getCullAABB` 覆写返回实际文本尺寸

### 事件

- 子节点优先，`return true` 拦截
- `raycast_target` 只拦截 MousePressed/Released/Moved，**不拦截 WheelMoved**

### 跨平台

- **禁止 `>nul`**：用 `>/dev/null`

---

## 测试

`tests/ui/` 下每个文件返回 `{name = "名称", create = function(parent)}`。`tests/gallery.lua` 注册。

当前主要测试场景：
- **Godot Containers** — 9 节演示所有容器特性（Fill/Expand/alignment/auto_size/Spacer/Scroll）
- **Game Settings** — 真实复杂 UI（TabView + BoxContainer + Scroll auto_track）
- **ProgressBar** — 容器重写版，静态/交互式水平垂直
- **Chat History** — ChatBubble + ListContainer + Scroll
- **Virtual List** — 虚拟化列表，3000 项数据仅实例化 ~12 个控件

---

## 依赖

| 库 | 路径 | 用途 |
|----|------|------|
| classic | `dependencies/classic.lua` | OOP |
| tween | `dependencies/tween.lua` | 动画（Scroll） |
| Lovebird | `dependencies/lovebird/` | 远程调试 :8000 |
| i18n | `dependencies/i18n/` | 本地化（zh-cn） |
