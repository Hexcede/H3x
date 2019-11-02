local Runner = require(script.Parent:WaitForChild("Runner"))
local Context = require(script.Parent:WaitForChild("Context"))

local completed
delay(2, function()
	assert(completed, "Runner execute test failed. Permanent yielding")
end)

local ctx = Context:Create("return true")
local Script = Runner:LoadContext(ctx)
assert(Script:Start(), "Runner return test failed.")
assert(Script:Start(), "Runner repeated return test failed.")

completed = true

local ctx2 = Context:Create("assert(abc123, 'Set environment test one failed') assert(getfenv(0).tostring, 'Environment test two failed')", {print = print, tostring = tostring, assert = assert, pcall = pcall, getfenv = getfenv, abc123 = "test1"})
local Script = Runner:LoadContext(ctx)
Script:Start()

local ctx3 = Context:Create("assert(abc123, 'Merge environment test failed.')", {abc123 = "test2"}, true)
local Script = Runner:LoadContext(ctx2)
Script:Start()

local ctx4 = Context:Create("assert(getfenv(0) and getfenv(1), 'Fenv test failed') assert(not pcall(getfenv, 2), 'Get environment security check failed.')")
local Script = Runner:LoadContext(ctx3)
Script:Start()

return nil