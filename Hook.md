This API is returned by `Sandbox:Load`. To use it override these functions with your own.

```lua
bool override, Variant overrideValue Hook:OnGetIndex(Context context, Variant tbl, Variant tblIndex, Variant tblValue)
```
`overrideValue` is the value that gets returned if `override` is true. Note: Values are still protected
```lua
bool override, Variant overrideValue Hook:OnSetIndex(Context context, Variant tbl, Variant tblIndex, Variant tblValue)
```
`overrideValue` is what the value gets set to if `override` is true
```lua
bool override, Variant overrideProtected Hook:OnProtectValue(Context context, Variant index, Variant value, Variant protectedValue)
```
`overrideProtected` is what is returned if `override` is true. `value` is the original value. `protectedValue` is the protected value.
```lua
bool override, Variant overrideProtected Hook:OnProtectFunction(Context context, Variant index, Variant value, Variant protectedValue)
```
`overrideProtected` is what is returned if `override` is true.

Example
```lua
function hook:OnGetIndex(context, tbl, index, value)
	if index == "anIndex" then
		return true, "ACustomValue"
	end
end
```
