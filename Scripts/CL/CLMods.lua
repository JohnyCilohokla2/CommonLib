if CL == nil then
	NKError("Common Lib error, initializing module outside of CL.lua!")
end
	
function CL:initializeHooks()
	for modID, mod in pairs(CL.tugMods) do
		if mod.instance then
			if mod.instance.initializeHooks then
				mod.instance:initializeHooks()
				mod.instance:loadHooks()
			end
		end
	end
end

function CL:ModifyBiomeData(biomeName, biome)
	for modID, mod in pairs(CL.tugMods) do
		if mod.instance then
			if mod.instance.ModifyBiomeData then
				mod.instance:ModifyBiomeData(biomeName, biome)
			end
		end
	end
end