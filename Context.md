```lua
static Context context Context:Create()
```
This creates a context.
```lua
function loadedFunc, Context ctx Context:Load(string code, table env, bool mergeMode=false)
```
Loads the code as a function and sets the environment
```lua
Tuple scriptReturnValues... Context:Execute(Tuple args...)
```
Executes the script with arguments (a vararg that can be accessed in user code as `...`) and returns a list of script return values (can also be multiple or none)
```lua
table environment Context:GetEnvironment()
```
Gets the script environment
```lua
void Context:SetEnvironment(table environment, bool mergeMode=false)
```
Sets the script environment
```lua
ProtectedFunction protectedFunction Context:InjectFunction(function func)
```
Returns a context-safe reference to the supplied function.
```lua
void Context:AddLibrary(string libraryName, Variant library)
```
Adds a library to the script context with a name and value
```lua
void Context:RemoveLibrary(libraryName)
```
Removes a library with the supplied name
```lua
void Context:Destroy()
```
Cleans up a Context.
