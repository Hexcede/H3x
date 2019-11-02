```lua
function loadedFunc, Context ctx, Hook hook Sandbox:Load(string code, table env, bool mergeMode=false)
```
This loads the supplied code as a function and sets the environment. This is the same as `Context:Load` with the exception that it creates a sandboxed environment if an environment is not provided. Generally you should provide a sandboxed environment if you provide one at all.
```lua
table environment, Hook hook Sandbox:MakeEnvironment(Context context)
```
This returns a sandboxed environment and a `Hook` (see [Hook API](Hook.md)) for the supplied context.
