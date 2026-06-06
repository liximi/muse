# UI 框架待办

从 [UI框架全面优化计划.md](UI框架全面优化计划.md) 中提取的未完成 / 暂缓 / 已移除项。

---

## ✅ 已完成 (2026-06-06)

### TextInput 鼠标拖动选择文本

**根因**：`addHoverState` 直接覆盖 `widget.onMouseMoved`，不调用原始 handler。TextInput 构造中调用 `addHoverState(self)` 后，`TextInput:onMouseMoved`（拖选逻辑）被完全遮蔽。

**修复**：`addHoverState` 保存原始 `onMouseMoved` 引用并在新函数中先调用它，再做 hover 检测。同时修正 `onMousePressed` 返回 `true` 拦截事件防止父容器干扰。

### TextInput 单行模式

新增 `single_line` 参数：Enter 不换行，触发 `on_submit` 回调；粘贴多行文本时自动过滤换行符。

### Tooltip widget

鼠标悬停提示，延迟显示、跟随鼠标、屏幕边界自动翻转。`render_layer = TOOLTIP`，注册为 UiManager 根 widget。`destroyAll()` 生命周期管理。

### Dropdown / ComboBox widget

下拉选择框，popup 全屏 DROPDOWN 层 + 绝对定位、上下/左右边界翻转、超出滚动、`hide_slider_when_cannot_scroll`、选中不重建列表（保留滚动位）、`destroyAll()` 清理。

### ScrollContainer 滚动条增强

新增 `v_bar_pad_top/bottom`、`h_bar_pad_left/right` 边距参数；`v_bar_min_h`/`h_bar_min_w` 最小高度/宽度（空间不足时按比例缩减边距）；`block_min_len` 滑块最小长度（SliderBar 配合）。

### Dropdown 相关修复

- popup 子树递归统一 DROPDOWN 渲染层（修复文字绘制顺序和滚动裁剪）
- popup 拦截 MouseMoved（修复背后 widget 焦点争抢闪烁）
- `_open` 布尔字段重命名 `_is_open`（避免与方法 `_open()` 冲突）
- 滚动条 `scrollbar_edge_pad` 边距、`scroll_bottom_pad` 底部留白、`scrollable_h` 正确设为内容高度（修复滚动范围）
- Gallery 滚动列表同步修复 `scrollable_h`

---

## 🔧 待修复

（暂无）

---

## ⏭ 暂缓

### Measure 阶段（原 5-1）

布局系统引入双向协商机制：子元素通过 `measure(max_w, max_h)` 声明最小/首选尺寸，父容器根据子元素需求和自身策略分配空间。当前为纯父→子单向布局。

**暂缓理由**：当前系统工作正常（Box 用 `getScaledSize()`，TextInput 有 `height_adaptive`）。这是布局引擎 2.0 级别变更（~400 行），应在积累更多使用需求后再设计。

**触发条件**：Tooltip/Dropdown 落地后暴露了布局系统不足；或 TextInput 高度自适应需要容器联动。

---

## ❌ 已移除

### UI 上下文隔离（原 5-4）

将 UiManager 从单例改为可实例化类。

**移除理由**：LÖVE 是单窗口引擎，无真实多 Manager 需求。焦点作用域和子树主题继承均可在单 Manager 内解决。

---

### `newButtonStateStyle` 传表改造（原 6-4）

9 个位置参数改为单个 table 参数。

**移除理由**：传表后函数退化为 `{datas.text, datas.text_color, ...}` 字段拷贝，无抽象价值。位置参数自带类型提示效果。
