if CL == nil then
	NKError("Common Lib error, initializing module outside of CL.lua!")
end

function CL:initializeMods()
	for modID, mod in pairs(CL.mods) do
		mod:initialize()
	end
end
	
function CL:initializeHooks()
	for modID, mod in pairs(CL.mods) do
		mod:loadHooks()
	end
end


function CL:InitializeTUGMods()
	for modID, mod in pairs(CL.tugMods) do
		mod:Initialize()
	end
end

function CL:EnterTUGMods()
	for modID, mod in pairs(CL.tugMods) do
		mod:Enter()
	end
end

function CL:LeaveTUGMods()
	for modID, mod in pairs(CL.tugMods) do
		mod:Leave()
	end
end

function CL:ProcessTUGMods()
	for modID, mod in pairs(CL.tugMods) do
		mod:Process()
	end
end

function CL:RegisterCrafting(craftingSystem)
	for modID, mod in pairs(CL.tugMods) do
		if mod.RegisterCrafting then
			mod:RegisterCrafting(craftingSystem)
		end
	end
end

function CL:ModifyBiomeData(biomeName, biome)
	for modID, mod in pairs(CL.tugMods) do
		if mod.ModifyBiomeData then
			mod:ModifyBiomeData(biomeName, biome)
		end
	end
end

function CL:ProcessCloseInventory()
	for modID, mod in pairs(CL.tugMods) do
		if mod.CloseInventory then
			mod:CloseInventory()
		end
	end
end