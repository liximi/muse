# Box（旧版，逐步废弃）

Flexbox 式布局容器，通过 `flex_grow`/`flex_shrink` 伸缩分配空间。已被 **Godot Container 路线**替代。

> **新代码请使用 BoxContainer / MarginContainer / CenterContainer**。Box 仅保留以支持仍依赖它的旧代码。

**继承链：** `Widget` → `Box`

## 与 BoxContainer 的对比

| 特性 | Box（旧） | BoxContainer（新） |
|------|-----------|-------------------|
| 布局模型 | CSS Flexbox 风格 | Godot 风格 |
| 伸缩机制 | `flex_grow` / `flex_shrink` 两组值 | `FILL + EXPAND` 位标志 |
| 最小尺寸 | `min_size` 参数 | `getMinimumSize()` 多态方法 |
| 交叉轴对齐 | `cross_align` | 统一由 `fitChildInRect` 处理 |
| 弹性占位 | 无 | `addSpacer()` |

详细说明请参阅旧版 Box 文档。迁移指南：将 `flex_grow = 1` 替换为 `h_size_flags / v_size_flags = FILL + EXPAND`，将 `cross_align = "stretch"` 替换为默认的 `FILL`。
