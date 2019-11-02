local tests = {
	"Test.Context",
	"Test.Sandbox",
	"Test.Runner"
}

for _, test in ipairs(tests) do
	spawn(function()
		require(script.Parent:WaitForChild(test))
	end)
end