
NKPrint("Common Lib - Initizing\n")

if CL == nil then
	CL = Class.Subclass("CL")
end
include("Scripts/CL/CLCommon.lua")
include("Scripts/CL/CLHooks.lua")
include("Scripts/CL/CLMods.lua")
include("Scripts/CL/CLQuats.lua")
include("Scripts/CL/CLFrameLayouts.lua")

NKPrint("Common Lib - Finalized\n")