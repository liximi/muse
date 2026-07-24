# Box (Legacy, replaced by BoxContainer)

Flexbox-style layout container using `flex_grow`/`flex_shrink`. **Replaced by the Godot Container route.**

> **New code should use BoxContainer.** Box is kept only for legacy compatibility.

**Inheritance:** `Widget` → `Box`

## Migration

| Box (old) | BoxContainer (new) |
|-----------|-------------------|
| `flex_grow = 1` | `h_size_flags / v_size_flags = FILL + EXPAND` |
| `cross_align = "stretch"` | Default `FILL` |
| `min_size` param | `getMinimumSize()` polymorphic method |

For details, refer to the legacy Box documentation.
