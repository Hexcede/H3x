-- H3x V1.3
local Context = require(script.Parent:WaitForChild("Context"))
local Dispatch = script:WaitForChild("Dispatch")
local Runner = {}

function Runner:LoadFunction(func, ctx)
	assert(func, "Please provide a function to load.")
	assert(typeof(func) == "function", "Provided value isn't a function.")
	local Script = {}
	local newScript = Dispatch:Clone()
	
	local Shared = require(newScript:WaitForChild("Shared"))
	Shared.Context = ctx
	
	Script.ScriptInstance = newScript
	Script.Shared = Shared
	
	if ctx then
		Script.Context = ctx
		ctx.TargetScript = Script
	end
	
	Script.TargetFunction = func
	function Script:Start(...)
		return Runner:StartScript(self, ...)
	end
	function Script:Stop()
		return Runner:StopScript(self)
	end
	
	newScript.Parent = script
	return Script
end

function Runner:LoadScript(scr, env, mergeMode)
	assert(scr, "Please provide a script.")
	assert(scr.IsA and scr:IsA("Script"), "Provided value isn't a Script instance.")
	
	assert(pcall(function()
		return scr.Source
	end), "The Runner cannot load scripts in this context. (Doesn't have permission to script source)")
	
	local ctx = Context:Create()
	ctx:Load(scr.Source, env, mergeMode)
	
	return Runner:LoadContext(ctx)
end

function Runner:LoadContext(ctx)
	assert(ctx, "Please provide a Context.")
	
	return Runner:LoadFunction(ctx:GetFunction(), ctx)
end

function Runner:StopScript(scr)
	if typeof(scr) == "Instance" then
		scr = {ScriptInstance = scr}
	end
	assert(typeof(scr.ScriptInstance) == "Instance" and scr.ScriptInstance:IsA("Script"), "Not a valid script.")
	scr.ScriptInstance.Disabled = true
end

function Runner:StartScript(scr, ...)
	if typeof(scr) == "Instance" then
		scr = {ScriptInstance = scr}
	end
	assert(typeof(scr.ScriptInstance) == "Instance" and scr.ScriptInstance:IsA("Script"), "Not a valid script.")
	local Shared = scr.Shared
	
	local argPtr = Context.Pointer(...) -- Used to performantly pass arguments
	Shared.CompleteEvent = Shared.CompleteEvent or Instance.new("BindableEvent")
	Shared.DispatchEvent = Shared.DispatchEvent or Instance.new("BindableEvent")
	Shared.DispatchFunction = scr.TargetFunction
	
	scr.ScriptInstance.Disabled = false -- Enable the script
	spawn(function()
		Shared.DispatchEvent:Fire(argPtr) -- Dispatch the script
	end)
	local returnPtr = Context.Pointer(Shared.CompleteEvent.Event:Wait()) -- Used to performantly (and easily) store return values
	
	return returnPtr()
end

return Runner