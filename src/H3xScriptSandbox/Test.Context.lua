local Context = require(script.Parent:WaitForChild("Context"):Clone())

local ctx = Context:Create("assert(abc123, 'Set environment test one failed') assert(getfenv(0).tostring, 'Environment test two failed')", {print = print, tostring = tostring, assert = assert, pcall = pcall, getfenv = getfenv, abc123 = "test1"})
ctx:Execute()

local ctx2 = Context:Create("assert(abc123, 'Merge environment test failed.')", {abc123 = "test2"}, true)
ctx2:Execute()

local ctx3 = Context:Create("assert(getfenv(0) and getfenv(1), 'Fenv test failed') assert(not pcall(getfenv, 2), 'Get environment security check failed.')")
ctx3:Execute()

return nil