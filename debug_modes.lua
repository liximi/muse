-- 临时脚本：打印 getFullscreenModes 返回的实际格式
local modes = love.window.getFullscreenModes()
print("getFullscreenModes count: " .. #modes)
for i, m in ipairs(modes) do
    print(i .. ":")
    for k, v in pairs(m) do
        print("  " .. tostring(k) .. " = " .. tostring(v))
    end
    if i >= 3 then break end
end
