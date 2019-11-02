-- H3x V1.2
local Context = require(script.Parent:WaitForChild("Context"):Clone())

local Sandbox = {}

function Sandbox:Load(code, env, mergeMode)
	local ctx = Context:Create()
	local loadedFunc = ctx:Load(code)
	local hook
	if not env then
		env, hook = Sandbox:MakeEnvironment(ctx)
	end
	ctx:SetEnvironment(env, mergeMode)
	return loadedFunc, ctx, hook
end

local function toTable(...) -- Tuple to table
	local tbl = {}
	for i=1, select("#", ...) do
		tbl[i] = select(i, ...)
	end
	return tbl, select("#", ...)
end

local rootEnv = getfenv()
function Sandbox:MakeEnvironment(ctx)
	local realEnv
	local hook = {}
	local env = ctx:GetEnvironment()
	env.game = nil
	env.workspace = nil
	env.Game = nil
	env.Workspace = nil
	
	local wrapFunction
	local protect
	protect = function(index, value)
		local protected = value
		if typeof(value) == "Instance" or value == ctx.Nil then
			protected = nil
		elseif typeof(value) == "function" then
			protected = wrapFunction(index, value)
		elseif typeof(value) == "table" or type(value) == "userdata" then
			local result
			if typeof(value) == "table" then
				result = {}
			else
				result = newproxy(true)
			end
			local meta = getmetatable(result) or {}
			meta.__index = function(_, tblIndex)
				local tblValue = value[tblIndex]
				if hook.OnGetIndex then
					local override, overrideValue = hook:OnGetIndex(ctx, value, tblIndex, tblValue)
					if override then
						return protect(overrideValue)
					end
				end
				return protect(tostring(index).."."..tostring(tblIndex), tblValue)
			end
			meta.__newindex = function(_, tblIndex, tblValue)
				if hook.OnSetIndex then
					local override, overrideValue = hook:OnSetIndex(ctx, value, tblIndex, tblValue)
					if override then
						tblValue = protect(overrideValue)
					end
				end
				value[tblIndex] = tblValue
			end
			meta.__call = function()
				local canEnv = pcall(function()
					getfenv(3)
				end)
				if not canEnv or getfenv(2) ~= rootEnv then
					return wrapFunction(index, value)
				end
				meta.__mode = "kv"
				meta.__index = nil
				meta.__call = nil
				setmetatable(meta, {__mode = "kv"})
				meta = nil
				value = nil
				warn("Garbage collected sandbox object.")
			end
			meta.__metatable = "The metatable is locked"
			if typeof(value) == "table" then
				setmetatable(result, meta)
			end
			protected = result
		end
		
		if hook.OnProtectValue then
			local override, overrideProtected = hook:OnProtectValue(ctx, index, value, protected)
			if override then
				return overrideProtected
			end
		end
		
		return protected
	end
	
	wrapFunction = function(index, value)
		if hook.OnProtectFunction then
			local override, overrideProtected = hook:OnProtectFunction(ctx, index, value)
			if override then
				value = overrideProtected
			end
		end
		
		return ctx:InjectFunction(function(...)
			local results, len = toTable(value(...)) -- Contrary to popular belief simply doing {value(...)} doesn't suffice. If there are nil indexes than the table will not include anything beyond.
			
			local function stack(next, ...)
				if next then
					return next(), ...
				else
					return ...
				end
			end
			
			for i, value in ipairs(results) do
				results[i] = protect(value)
			end
			
			local stackList = {}
			for i=1, len do
				local idx = #stackList+1
				stackList[idx] = function()
					return stack(stackList[idx+1], results[i])
				end
			end
			
			return stack(stackList[1])
		end)
	end
	
	env.require = protect("require", function(library)
		return ctx.Libraries[library] or error("Cannot require non existant library: "..library)
	end)
	
	local overrides = function()end
	
	local meta
	meta = {
		__index = function(_, index)
			local value = env[index]
			
			if hook.OnGetIndex then
				hook:OnGetIndex(ctx, env, index)
			end
			
			return protect(index, value)
		end,
		__newindex = function(_, index, value)
			if hook.OnSetIndex then
				hook:OnSetIndex(ctx, env, index, value)
			end
			
			env[index] = value
		end,
		__call = function()
			if getfenv(2) ~= rootEnv then
				return error("attempt to call a table value")
			end
			meta.__mode = "kv"
			meta.__index = nil
			meta.__call = nil
			setmetatable(meta, {__mode = "kv"})
			meta = nil
			warn("Garbage collected sandbox environment.")
		end,
		__metatable = "The metatable is locked"
	}
	realEnv = setmetatable({}, meta)
	return realEnv, hook
end

return Sandbox