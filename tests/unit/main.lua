-- Transform 单元测试入口
-- 运行：love tests/unit
-- 设置 Class 全局（Transform 不需要 Class，但为了安全保留）
Class = require "dependencies.classic"

local test_transform = require "tests.unit.test_transform"

function love.load()
	test_transform.run()
end

function love.draw()
	love.graphics.clear(0.1, 0.1, 0.1)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Transform unit tests running... check console output.", 20, 20)
end
