# Fonts（字体管理器）

Fonts 是 Muse 框架的字体注册与管理模块。它提供统一的字体加载、缓存和查询机制，所有需要文本渲染的 widget（Text、Button、TextInput 等）都通过它获取 `love.graphics.Font` 对象。

## 核心机制

### 懒加载与缓存

Fonts 模块采用**按需懒加载**策略：

- 每个字体条目以 key（字符串）标识，内部存储 TTF 文件路径（`_file` 字段）和按字号缓存的 `love.graphics.Font` 对象
- 首次调用 `getFont(key, size)` 时，执行 `love.graphics.newFont(file, size)` 创建字体对象并缓存
- 后续同 key + size 的请求直接返回缓存对象，避免重复创建

```lua
-- 首次调用：加载 TTF 并缓存
local f1 = Fonts:getFont("default", 20)  -- 创建 love.graphics.Font

-- 再次调用：命中缓存，直接返回
local f2 = Fonts:getFont("default", 20)  -- f1 == f2
```

### 字号独立缓存

同一字体的不同字号各自独立缓存——`"default"` 的 12px、16px、20px 分别创建三个 `love.graphics.Font` 对象，互不影响。

## 内置字体

Muse 内置了 [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC) 系列字体（SIL Open Font License 1.1），存放在 `ui/fonts/` 目录下：

| Key | 文件 | 字重 | 用途 |
|-----|------|------|------|
| `"default"` | `NotoSansSC-Regular.ttf` | Regular（400） | 正文、按钮、输入框等通用 UI 文本。**构造时预创建了 16px 实例** |
| `"default_thin"` | `NotoSansSC-Thin.ttf` | Thin（250） | 极细字重 |
| `"default_light"` | `NotoSansSC-Light.ttf` | Light（300） | 较轻字重 |
| `"default_bold"` | `NotoSansSC-Bold.ttf` | Bold（700） | 加粗文本、标题强调 |
| `"default_black"` | `NotoSansSC-Black.ttf` | Black（900） | 超粗字重 |
| `"debug"` | `NotoSansSC-Light.ttf` | Light（300） | 调试信息渲染（Button、Image、ScrollContainer 的调试模式） |

> **注意**：`"debug"` 与 `"default_light"` 使用相同的 TTF 文件，但作为独立 key 存在，缓存空间互不影响。

## API

### `Fonts:getFont(key, size)`

获取指定 key 和字号的字体对象。如果该字号尚未创建，则自动加载并缓存。

```lua
---@param key   string  字体注册 key
---@param size  number  字号（像素）
---@return love.graphics.Font
local font = Fonts:getFont("default", 16)
```

### `Fonts:newFont(key, file, size)`

注册一个新字体并可选预创建指定字号的实例。

```lua
---@param key   string  新字体的注册 key（不可与已有 key 重复）
---@param file  string  TTF 文件的路径
---@param size  number  预创建的字号，默认 16
---@return love.graphics.Font  返回预创建的字体对象
Fonts:newFont("my_font", "assets/fonts/MyCustomFont.ttf", 18)
```

> **注意**：如果 key 已存在，`newFont` 会**覆盖**原有条目。

### `Fonts:hasFont(key)`

检查指定 key 是否已在 Fonts 中注册。

```lua
if Fonts:hasFont("my_font") then
    print("my_font 已注册")
end
```

## 使用方式

### 方式一：通过 widget 构造参数

Text 和 TextInput 等 widget 构造时接受 `font_key` 和 `font_size`：

```lua
local label = Text({
    text = "Hello, Muse!",
    font_key = "default_bold",
    font_size = 20,
})
```

### 方式二：通过 widget 实例方法

```lua
-- 同时设置字体和字号
label:setFont("default", 18)

-- 仅修改字号
label:setFontSize(24)

-- 获取当前字体对象
local font = label:getFont()

-- 获取当前字体 key
local key = label:getFont(true)

-- 获取当前字号
local size = label:getFontSize()
```

### 方式三：通过主题系统

在主题中统一设置默认字体：

```lua
local Theme = require "ui.theme"

local MyTheme = Theme:extend()
function MyTheme:new()
    Theme.new(self)
    self.text.font_key = "default_bold"
    self.text.font_size = 18
    self.textinput.font_key = "default"
    self.textinput.font_size = 16
end
```

### 方式四：直接获取用于原生 LÖVE 绘制

当需要在 widget 系统之外直接使用 LÖVE API 绘制文本时：

```lua
local Fonts = require "ui.fonts"

function love.draw()
    local font = Fonts:getFont("default", 14)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FPS: 60", font, 10, 10)
end
```

## 注册自定义字体

```lua
local Fonts = require "ui.fonts"

-- 1. 注册字体（将 TTF 文件放入 ui/fonts/ 或你的项目资源目录）
Fonts:newFont("pixel", "ui/fonts/PixelFont.ttf", 12)

-- 2. 直接使用
local font = Fonts:getFont("pixel", 24)

-- 3. 或在 widget 中使用
local label = Text({
    text = "像素风格",
    font_key = "pixel",
    font_size = 24,
})
```

## 字体加载的生命周期

```
Fonts:newFont("my_font", "path.ttf", 16)
        │
        ├──► self["my_font"] = { _file = "path.ttf" }
        └──► self:getFont("my_font", 16)
                │
                ├──► self["my_font"][16] = love.graphics.newFont("path.ttf", 16)
                └──► return self["my_font"][16]
```

后续请求：

```
Fonts:getFont("my_font", 20)
        │
        ├──► self["my_font"][20] 不存在
        ├──► self["my_font"][20] = love.graphics.newFont("path.ttf", 20)
        └──► return self["my_font"][20]

Fonts:getFont("my_font", 20)  -- 再次调用
        │
        ├──► self["my_font"][20] 已缓存
        └──► return self["my_font"][20]
```

## Widget 中的字体流转

以 Button 为例，展示字体如何在 widget 体系中流转：

```
Theme / datas 定义 font_key + font_size
        │
        ▼
Button 构造函数
        │
        ├──► datas.font_key / theme.button.normal.font_size
        │
        ▼
Button 内部 Text 子 widget
        │
        ├──► Text:setFont(font_key, font_size)
        │     ├──► 校验 Fonts[font_key] 是否存在
        │     └──► self.__text:setFont(Fonts:getFont(font_key, font_size))
        │
        ▼
状态切换（normal → hover → pressed …）
        │
        └──► Components.applyButtonTextStyle(button, new_style)
              └──► button.text:setFontSize(new_style.font_size)
```

## 常见问题

### Q: 字体未注册错误

```
Text:setFont|Unregistered fonts: xxx
```

**原因**：使用了未注册的 `font_key`。所有字体必须先通过 `Fonts:newFont()` 注册或使用内置 key。

**解决**：
```lua
-- 确保在使用前注册
Fonts:newFont("my_font", "path/to/font.ttf", 16)
```

### Q: 修改 font_size 后文本尺寸未更新

**原因**：`Text:setFontSize()` 内部会调用 `updateTextLayout()` 刷新布局。但如果直接操作 `love.graphics.Font` 对象，widget 不会感知变化。

**解决**：始终通过 widget 的 `setFont` / `setFontSize` 方法修改字体。

### Q: 不同 widget 之间的字体是否共享？

是的。`Fonts:getFont("default", 16)` 始终返回同一个 `love.graphics.Font` 对象，多个 Text widget 引用同一对象不会重复加载。

### Q: 如何动态切换字体而不重新创建 widget？

```lua
-- 运行时切换字体
label:setFont("default_bold", 18)   -- 切换到粗体
label:setFont("default", 14)        -- 切回常规
```
