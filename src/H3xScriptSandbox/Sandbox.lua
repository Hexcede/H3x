-- H3x V1.3
local Context = require(script.Parent:WaitForChild("Context"):Clone())

local Sandbox = {}

function Sandbox:CreateStack()
	local stack = {}
	stack.Values = setmetatable({}, {__mode = "v"}) -- Prevent value from being held in memory
	
	-- Note: The length operator (#) counts only numeric indexes which is used here
	
	function stack:Is(...)
		-- Get length of input
		local length = select("#", ...)
		
		-- Check if lengths match
		if length ~= #self then
			-- Length doesn't match
			return false
		end
		
		for i=1, length do
			-- Check if items match
			if self[i] ~= select(i, ...) then
				-- Items do not match
				return false
			end
		end
		
		-- Everything passed
		return true
	end
	
	function stack:Get(index)
		assert(typeof(index) == "number", "Given index is not a number.")
		local item = {}
		
		item.Value = self.Values[index] -- Value of item
		item.Index = self[index] -- String index (name)
		item.Position = index -- Numeric index (position)
		
		return setmetatable(item, {__mode = "v"}) -- Prevent value from being held in memory
	end
	
	function stack:Append(name, value)
		-- Insert the value and index name
		table.insert(self.Values, value)
		table.insert(self, name)
		
		-- For use in scripts (e.g. stack.coroutine or stack["coroutine"] will return the global coroutine if it is part of the stack)
		self[name] = value
	end
	
	function stack:Length()
		-- Return length of self
		return #self
	end
	
	function stack:Clone()
		-- Create a new stack
		local newStack = Sandbox:CreateStack()
		
		-- Append all key-value pairs
		for i, index in ipairs(self) do
			newStack:Append(index, self.Values[i])
		end
		
		-- Return the cloned stack
		return newStack
	end
	
	return stack
end

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
	protect = function(index, value, stack)
		local protected = value
		if typeof(value) == "Instance" or value == ctx.Nil then
			protected = nil
		elseif typeof(value) == "function" then
			protected = wrapFunction(index, value, stack)
		elseif typeof(value) == "table" or type(value) == "userdata" then
			local result
			if typeof(value) == "table" then
				result = {}
			else
				result = newproxy(true)
			end
			local meta = getmetatable(result) or {}
			meta.__index = function(_, tblIndex)
				local newValue
				local tblValue = value[tblIndex]
				if hook.OnGetIndex then
					local override, overrideValue = hook:OnGetIndex(ctx, value, tblIndex, tblValue, stack:Clone())
					if override then
						newValue = protect(tblIndex, overrideValue, stack)
						if stack then
							stack:Append(tblIndex, newValue)
						end
						return newValue
					end
				end
				newValue = protect(tblIndex, tblValue, stack)
				if stack then
					stack:Append(tblIndex, newValue)
				end
				return newValue
			end
			meta.__newindex = function(_, tblIndex, tblValue)
				if hook.OnSetIndex then
					local override, overrideValue = hook:OnSetIndex(ctx, value, tblIndex, tblValue, stack:Clone())
					if override then
						tblValue = protect(tblIndex, overrideValue, stack)
					end
				end
				value[tblIndex] = tblValue
			end
			meta.__call = function()
				local canEnv = pcall(function()
					getfenv(3)
				end)
				if not canEnv or getfenv(2) ~= rootEnv then
					return wrapFunction(index, value, stack)
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
			local override, overrideProtected = hook:OnProtectValue(ctx, index, value, protected, stack)
			if override then
				return overrideProtected
			end
		end
		
		return protected
	end
	
	wrapFunction = function(index, value, stack)
		if hook.OnProtectFunction then
			local override, overrideProtected = hook:OnProtectFunction(ctx, index, value, stack)
			if override then
				value = overrideProtected
			end
		end
		
		return ctx:InjectFunction(function(...)
			local results, len = toTable(value(...)) -- Contrary to popular belief simply doing {value(...)} doesn't suffice. If there are nil indexes than the table will not include anything beyond.
			
			local function pushStack(next, ...)
				if next then
					return ..., next()
				else
					return ...
				end
			end
			
			for i, value in ipairs(results) do
				results[i] = protect(i, value, stack)
			end
			
			local stackList = {}
			for i=2, len do
				local idx = #stackList+1
				stackList[idx] = function()
					return pushStack(stackList[idx+1], results[i])
				end
			end
			
			return pushStack(stackList[1], results[1])
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
			
			local stack = Sandbox:CreateStack()
			stack:Append(index, value)
			if hook.OnGetIndex then
				hook:OnGetIndex(ctx, env, index, stack:Clone())
			end
			
			return protect(index, value, stack)
		end,
		__newindex = function(_, index, value)
			local stack = Sandbox:CreateStack()
			stack:Append(index, value)
			if hook.OnSetIndex then
				hook:OnSetIndex(ctx, env, index, value, stack:Clone())
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