local Shared = require(script:WaitForChild("Shared"))

while true do
	Shared.DispatchEvent = Shared.DispatchEvent or Instance.new("BindableEvent")
	local argPtr = Shared.DispatchEvent.Event:Wait()
	if Shared.DispatchFunction and Shared.CompleteEvent then
		coroutine.wrap(function()
			Shared.CompleteEvent:Fire(Shared.DispatchFunction(argPtr()))
		end)()
		script.Disabled = true
	end
end