local sbx = script.Parent:WaitForChild("Sandbox"):Clone()
sbx.Parent = script.Parent
local Sandbox = require(sbx)
sbx:Destroy()

local test, ctx = Sandbox:Load([[
assert(not game, "Instance reference security check one failed.")
assert(not script, "Instance reference security check two failed.")
assert(not stats(), "Instance return security check failed.")
assert(not pcall(getfenv, 3), "Get environment security check failed.")
assert(abc123, "SetEnvironment test failed.")
]])

ctx:SetEnvironment({abc123 = "abc"}, true)

test()
ctx:Destroy()

if ctx.ThreadWatcherImplemented then
	local test, testCtx = Sandbox:Load([[
	coroutine.yield()
	return true
	]])
	
	local thread = coroutine.running()
	spawn(function()
		assert(test(), "Return/yield test failed")
		testCtx:Destroy()
		coroutine.resume(thread)
	end)
	
	coroutine.yield()
end

return nil