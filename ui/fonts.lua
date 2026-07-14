local muse = require("init")

local Fonts = {
    default = {
        _file = muse.resolve("ui/fonts/NotoSansSC-Regular.ttf")
    },
    default_thin = {
        _file = muse.resolve("ui/fonts/NotoSansSC-Thin.ttf")
    },
    default_light = {
        _file = muse.resolve("ui/fonts/NotoSansSC-Light.ttf")
    },
    default_bold = {
        _file = muse.resolve("ui/fonts/NotoSansSC-Bold.ttf")
    },
    default_black = {
        _file = muse.resolve("ui/fonts/NotoSansSC-Black.ttf")
    },
    debug = {
        _file = muse.resolve("ui/fonts/NotoSansSC-Light.ttf")
    }
}

function Fonts:newFont(key, file, size)
    size = size or 16
    self[key] = {
        _file = file
    }
    return self:getFont(key, size)
end

---@param key string
---@param size number
function Fonts:getFont(key, size)
    local font = self[key][size]
    if not font then
        font = love.graphics.newFont(self[key]._file, size)
        self[key][size] = font
    end
    return font
end

function Fonts:hasFont(key)
    return self[key] ~= nil
end

return Fonts
