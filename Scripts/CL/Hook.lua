include("Scripts/Core/Common.lua")

if HookClass == nil then
	HookClass = EternusEngine.Class.Subclass("HookClass")
end

function HookClass:Constructor( args, name )
	self.cl_mod = mod
	self.cl_name = name
	CL.println()
end

function HookClass:initialize()

end

function HookClass:_initialize()
	if (self.cl_initialized==nil) then
		self:initialize()
	end
	self.cl_initialized = true
end

-- default callback
function HookClass:call(object, ...)
	CL.println("lol")
end