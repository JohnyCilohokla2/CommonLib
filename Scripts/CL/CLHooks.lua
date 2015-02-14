if CL == nil then
	NKError("Common Lib error, initializing module outside of CL.lua!")
end

if CLHook == nil then
	CLHook = EternusEngine.Class.Subclass("CLHook")
	CL.hooks = {}
	CL.hooks.Abort = {"abort"}
	CL.hooks.Continue = {"continue"}
	CL.hooks.Default = {"default"}
end

function CL:hook(name, object, ...)
	if CL.hooks[name]~=nil then
		for hookID, hook in pairs(CL.hooks[name]) do
			local ret = hook.hook[hook.call](hook.hook, object, ...)
			if ((ret ~= nil) and (ret ~= CL.hooks.Continue)) then
				return ret
			end
			if ((ret ~= nil) and (ret ~= CL.hooks.Default)) then
				return CL.hooks.Continue
			end
		end
	end

end

function CL:addHook(name, hook, call)
	hook:_initialize()
	CL.println("Adding new hook "..hook.cl_name.."("..name..")")
	if (CL.hooks[name] == nil) then
		CL.hooks[name] = {}
	end
	local hookObject = {}
	hookObject.hook = hook
	hookObject.call = call or "call"
	table.insert(CL.hooks[name], hookObject)
end
