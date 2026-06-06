# UI 框架待办

从 [UI框架全面优化计划.md](UI框架全面优化计划.md) 中提取的未完成 / 暂缓 / 已移除项。

---

## 🔧 待修复

### TextInput 鼠标拖动选择文本 ✅ 已修复 (2026-06-06)

**根因**：`addHoverState` 直接覆盖 `widget.onMouseMoved`，不调用原始 handler。TextInput 构造中调用 `addHoverState(self)` 后，`TextInput:onMouseMoved`（拖选逻辑）被完全遮蔽。

**修复**：`addHoverState` 保存原始 `onMouseMoved` 引用并在新函数中先调用它，再做 hover 检测。同时修正 `onMousePressed` 返回 `true` 拦截事件防止父容器干扰。

---

## ⏭ 暂缓

### Measure 阶段（原 5-1）

布局系统引入双向协商机制：子元素通过 `measure(max_w, max_h)` 声明最小/首选尺寸，父容器根据子元素需求和自身策略分配空间。当前为纯父→子单向布局。

**暂缓理由**：当前系统工作正常（Box 用 `getScaledSize()`，TextInput 有 `height_adaptive`）。这是布局引擎 2.0 级别变更（~400 行），应在积累更多使用需求后再设计。

**触发条件**：Tooltip/Dropdown 落地后暴露了布局系统不足；或 TextInput 高度自适应需要容器联动。

---

## ⏭ 跳过的 Widget

### Tooltip

鼠标悬停提示，需要跨层级渲染能力。

**现状**：渲染层分离（5-2）已完成，`RENDER_LAYERS.TOOLTIP = 100` 已预留，基础设施就绪。

---

### Dropdown / ComboBox

下拉选择框，需要弹出层 + 列表选择 + 点击外部关闭。

**现状**：渲染层分离已完成，Modal 已有遮罩+外部点击关闭模式可参考。

---

## ❌ 已移除

### UI 上下文隔离（原 5-4）

将 UiManager 从单例改为可实例化类。

**移除理由**：LÖVE 是单窗口引擎，无真实多 Manager 需求。焦点作用域和子树主题继承均可在单 Manager 内解决。

---

### `newButtonStateStyle` 传表改造（原 6-4）

9 个位置参数改为单个 table 参数。

**移除理由**：传表后函数退化为 `{datas.text, datas.text_color, ...}` 字段拷贝，无抽象价值。位置参数自带类型提示效果。
