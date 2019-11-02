-- H3x V1.2
local Context = {}

Context.Nil = newproxy()

local setmetatable = setmetatable
local next = next
local tostring = tostring
local setfenv = setfenv
local loadstring = loadstring
local getfenv = getfenv
local pairs = pairs
local coroutine = coroutine
local assert = assert
local require = require
local script = script
local print = print
local warn = warn
local error = error
local debug = debug

local _IS_SHUTDOWN = false
local threads = {}
local function captureThread()
	local thread = coroutine.running()
	threads[thread] = coroutine.status(thread)
	
	if _IS_SHUTDOWN then
		error("The script is shutdown.") -- Kill the thread
	end
end

local function Pointer(...) -- A pointer function. For any arguments you give it it returns them back without using any tables or table functions.
	local func
	func = coroutine.wrap(function(...) -- Create a coroutine.
		captureThread()
		coroutine.yield(func) -- Yield the coroutine
		return ...
	end)
	return func(...)
end

local function wrapFunction(func)
	local f = coroutine.wrap(function(...)
		captureThread()
		local result = function()end
		while true do
			result = Pointer(func(coroutine.yield(result())))
		end
	end)
	f()
	
	return f
end
local context
local runSafe
local communicateShutdown
local function isCFunction(func)
	return not pcall(coroutine.wrap, func)
end
local function threadWatch(env)
	if env then
		local funcs = {}
		return setmetatable({}, {
			__index = function(_, index)
				captureThread()
				
				local value = env[index]
				return value
			end,
			__newindex = function(_, index, value)
				captureThread()
				
				env[index] = value
			end,
			__metatable = getmetatable(env)
		})
	end
end

if script.Name == "__Context" then -- We are in a new instance of Context
	Context.Libraries = {}
	
	context = coroutine.wrap(function()
		captureThread()
		
		local id = tostring(context):sub(#"function: "+1)
		
		local function applyEnv(func, env, mergeMode)
			if env then
				--env = threadWatch(env)
				if not mergeMode then
					setfenv(0, env)
				else
					local cenv = getfenv(0)
					
					for index, value in pairs(env) do
						if value == Context.Nil then
							value = nil
						end
						cenv[index] = value
					end
				end
			end
			if func then
				setfenv(func, getfenv(0))
			end
		end
		
		setfenv(0, threadWatch(getfenv(0)))
		applyEnv(nil, coroutine.yield(getfenv(0)))
		
		local __context_ = loadstring(coroutine.yield())
		
		while true do
			applyEnv(__context_, coroutine.yield(wrapFunction(__context_), getfenv(0)))
		end
	end)
	context()
	
	runSafe = coroutine.wrap(function()
		captureThread()
		
		local func
		while true do
			func = wrapFunction(coroutine.yield(func))
		end
	end)
	runSafe()
	
	communicateShutdown = coroutine.wrap(function()
		_IS_SHUTDOWN = true
		
		for thread, oldStatus in pairs(threads) do
			spawn(function()
				pcall(function()
					local steps = 0
					while coroutine.status(thread) ~= "dead" do -- Suspended, running, or normal.
						if steps == 100 then
							warn("A sandboxed thread may be inifitely yielding. Will try to invoke an error within ~30 seconds (900 resumes).")
						elseif steps > 100 and steps < 1000 then
							wait()
						elseif steps >= 1000 then
							warn("Failed to kill the thread allowing the thread to continue.")
							return true
						end
						
						local success = pcall(function()
							coroutine.resume(thread)
							steps = steps + 1
						end)
						if not success then
							wait()
						end
					end
				end)
			end)
		end
	end)
end
Context.ThreadWatcherImplemented = false -- Ignore me

Context.Pointer = Pointer -- For external use
function Context:Create(code, env, mergeMode)
	local scr = script:Clone() -- Make a new Context script
	scr.Name = "__Context" -- Signal to this script that it will be an instance of Context.
	local ctx = require(scr) -- Require the new instance
	
	if code then
		assert(typeof(code) == "string", "The provided code must be a string.")
		ctx:Load(code, env, mergeMode)
	end
	
	return ctx
end

function Context:Load(code, env, mergeMode)
	assert(context, "Invalid context.")
	self:SetEnvironment(env, mergeMode) -- Set the environment
	Context.__context, Context.environment = context(code) -- Compile code and set the context
	return Context.__context -- Return the context
end

function Context:Execute(...)
	assert(context, "Invalid context.")
	assert(Context.__context, "Context isn't loaded.")
	local ptr = Pointer(Context.__context(...)) -- Create pointer for return arguments
	Context.__context, Context.environment = context() -- Regenerate context
	return ptr() -- Get pointer value
end

function Context:GetEnvironment()
	assert(context, "Invalid context.")
	
	return Context.environment
end

function Context:SetEnvironment(env, mergeMode)
	assert(context, "Invalid context.")
	Context.__context, Context.environment = context(env, mergeMode) -- Set the new context
end

function Context:GetFunction()
	assert(Context.__context, "Invalid context")
	return Context.__context
end

function Context:InjectFunction(func)
	assert(context, "Invalid context.")
	return runSafe(func)
end

function Context:AddLibrary(name, lib)
	assert(context, "Invalid context.")
	Context.Libraries[name] = lib
end

function Context:RemoveLibrary(name)
	Context.Libraries[name] = nil
end

function Context:Destroy()
	if not _IS_SHUTDOWN then
		setmetatable(Context, {__mode = "kv"})
		pcall(function()
			self:GetEnvironment()() -- Gc environment
		end)
		self:SetEnvironment({})
		context = nil
		runSafe = nil
		communicateShutdown()
	end
end

return Context