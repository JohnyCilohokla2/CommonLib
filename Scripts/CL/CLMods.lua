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
		if mod.instance then
			mod.instance:Initialize()
		end
	end
end

function CL:EnterTUGMods()
	for modID, mod in pairs(CL.tugMods) do
		if mod.instance then
			mod.instance:Enter()
		end
	end
end

function CL:LeaveTUGMods()
	for modID, mod in pairs(CL.tugMods) do
		if mod.instance then
			mod.instance:Leave()
		end
	end
end

function CL:ProcessTUGMods()
	for modID, mod in pairs(CL.tugMods) do
		if mod.instance then
			mod.instance:Process()
		end
	end
end

function CL:RegisterCrafting(craftingSystem)
	for modID, mod in pairs(CL.tugMods) do
		if mod.instance then
			if mod.instance.RegisterCrafting then
				mod.instance:RegisterCrafting(craftingSystem)
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

function CL:ProcessCloseInventory()
	for modID, mod in pairs(CL.tugMods) do
		if mod.instance then
			if mod.instance.CloseInventory then
				mod.instance:CloseInventory()
			end
		end
	end
end