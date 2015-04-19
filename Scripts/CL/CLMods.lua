if CL == nil then
	NKError("Common Lib error, initializing module outside of CL.lua!")
end
	
function CL:initializeHooks()
	for modID, mod in pairs(CL.mods) do
		if mod.instance then
			if mod.instance.initializeHooks then
				mod.instance:initializeHooks()
				mod.instance:loadHooks()
			end
		end
	end
end

function CL:ModifyBiomeData(biomeName, biome)
	for modID, mod in pairs(CL.mods) do
		if mod.instance then
			if mod.instance.ModifyBiomeData then
				mod.instance:ModifyBiomeData(biomeName, biome)
			end
		end
	end
end

function CL:RegisterCrafting(craftingSystem)
	for modID, mod in pairs(CL.mods) do
		if mod.instance then
			if mod.instance.RegisterCrafting then
				mod.instance:RegisterCrafting(craftingSystem)
			end
		end
	end
end

function CL:SavePlayerData(player, outData)
	for modID, mod in pairs(CL.mods) do
		if mod.instance then
			if mod.instance.SavePlayerData then
				mod.instance:SavePlayerData(player, outData)
			end
		end
	end
end

function CL:RestorePlayerData(player, inData, version)
	for modID, mod in pairs(CL.mods) do
		if mod.instance then
			if mod.instance.RestorePlayerData then
				mod.instance:RestorePlayerData(player, inData, version)
			end
		end
	end
end