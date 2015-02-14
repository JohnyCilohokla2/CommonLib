include("Scripts/Core/Common.lua")
include("Scripts/CL/Mod.lua")

if CL_CommonLib == nil then
	CL_CommonLib = CLMod.Subclass("CL_CommonLib")
end

function CL_CommonLib:setup( args, path )
	self.m_name = "CommonLib"
	self.m_hookList = {"hook.lua"}
end

function CL_CommonLib:initialize()
	CL.println("CL_CommonLib initialize")
	CEGUI.SchemeManager:getSingleton():createFromFile("CL.scheme")
end

return CL_CommonLib