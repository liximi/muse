# Fonts — 字体管理器

字体管理器提供按 key + size 的懒加载与缓存机制。

## 已注册字体

`ui/fonts.lua` 中注册了以下字体（均使用 Noto Sans SC）：

| Key | 文件 | 用途 |
|-----|------|------|
| `default` | NotoSansSC-Regular.ttf | 默认正文 |
| `default_thin` | NotoSansSC-Thin.ttf | 细体 |
| `default_light` | NotoSansSC-Light.ttf | 轻体 |
| `default_bold` | NotoSansSC-Bold.ttf | 粗体 |
| `default_black` | NotoSansSC-Black.ttf | 黑体 |
| `debug` | NotoSansSC-Light.ttf | 调试文字 |

## 公有方法

| 方法 | 说明 |
|------|------|
| `Fonts:getFont(key, size)` | 获取字体对象。若该 key+size 的字体尚未创建，自动从 `_file` 懒加载并缓存 |
| `Fonts:newFont(key, file, size)` | 运行时注册新字体。自动创建首个 size 的字体对象 |
| `Fonts:hasFont(key)` | 检查指定 key 的字体是否已注册 |

## 懒加载缓存

```lua
-- 首次调用：从文件创建字体，缓存到 Fonts[key][size]
local font16 = Fonts:getFont("default", 16)

-- 再次调用同一 key+size：直接返回缓存
local font16_again = Fonts:getFont("default", 16)  -- 同一对象

-- 不同 size：创建新的字体对象
local font24 = Fonts:getFont("default", 24)
```

## 注册自定义字体

```lua
local Fonts = require "ui.fonts"
local muse = require("init")

Fonts:newFont("my_font", muse.resolve("assets/my_font.ttf"), 16)

-- 此后即可在其他地方使用
local my_font = Fonts:getFont("my_font", 20)
```

## 在 Text/TextInput 中使用

```lua
Text({
    text = "Hello",
    font_key = "default_bold",
    font_size = 24,
})
```
