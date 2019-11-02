#### Important
> In order for scripts to be runnable, the Runner API module must be in a location where Script instances can run.
```lua
Script Runner:LoadFunctionInScript(function func, Context ctx=nil)
```
Returns a Script object (not an instance!) which will run the given function. Optionally a Context can be supplied and the context will contain a variable TargetScript set to the Script object and the Script object will contain a Context property referencing the Context.
```lua
...returnValues Script:Start(...arguments)
```
Starts the given Script object, passing some arguments and yielding the return values of the script.
```lua
void Script:Stop()
```
Stops the given Script object.
#### Note
> There are also functions on Runner to start and stop scripts which take a Script object as their only arguments. These are StartScript and StopScript function and work exactly the same as they do on Script.
