include("Scripts/Core/Common.lua")
include("Scripts/Generation/PolarGenerator.lua")
include("Scripts/Generation/MtnForestsGenerator.lua")
include("Scripts/Generation/ForestsGenerator.lua")
include("Scripts/Generation/DesertGenerator.lua")
include("Scripts/Generation/JungleBiome.lua")
include("Scripts/Generation/MountainBiome.lua")

include("Scripts/CL/CLMods_Initialize.lua")

-------------------------------------------------------------------------------
-- TUG World generation
if TUGWorld == nil then
	TUGWorld = EternusEngine.BiomeClass.Subclass("TUGWorld")
end

-------------------------------------------------------------------------------
function TUGWorld:BuildTree()

	-- Individual biome files
	-- local PolarBiomes =  PolarGenerator.new():GetRoot()
	local MtnForestsBiomes =  MtnForestsGenerator.new():GetRoot()
	local ForestsBiomes =  ForestsGenerator.new():GetRoot()
	local DesertsBiomes =  DesertGenerator.new():GetRoot()
	local JungleBiomes =  JungleBiome.new():GetRoot()
	local WorldMountains = MountainBiome.new():GetRoot()

	local WorldToPineyWoods = self:Switch(ForestsBiomes, MtnForestsBiomes, self:Simplex((1.0/16.0)/70.0, 2), ForestsBiomes, MtnForestsBiomes) 
	WorldToPineyWoods:NKSetThreshold(0.4)
	WorldToPineyWoods:NKSetFalloff(0.5)
	WorldToPineyWoods:NKSetMaterialThreshold(0.49)

	local WorldToJungle = self:Switch(WorldToPineyWoods, JungleBiomes, self:Simplex((1.0/16.0)/80.0, 2), WorldToPineyWoods, JungleBiomes) 
	WorldToJungle:NKSetThreshold(0.22)
	WorldToJungle:NKSetFalloff(0.5)
	WorldToJungle:NKSetMaterialThreshold(0.49)

	local WorldToDesert = self:Switch(WorldToJungle, DesertsBiomes, self:Simplex((1.0/16.0)/70.0, 2), WorldToJungle, DesertsBiomes) 
	WorldToDesert:NKSetThreshold(0.28)
	WorldToDesert:NKSetFalloff(0.5)
	WorldToDesert:NKSetMaterialThreshold(0.49)

	-- local WorldToPolar = self:Switch(WorldToDesert, PolarBiomes, self:Simplex((1.0/16.0)/60.0, 2), WorldToDesert, PolarBiomes) 
	-- WorldToPolar:NKSetThreshold(0.23)
	-- WorldToPolar:NKSetFalloff(0.5)
	-- WorldToPolar:NKSetMaterialThreshold(0.49)
	
	-- Raise biome
	local raiseWorld = self:Add(WorldToDesert, self:Constant(100))

	combinedMountains = self:Max(WorldMountains, raiseWorld, WorldMountains, WorldToDesert)

	local raiseMountain = self:Add(combinedMountains, self:Constant(10000))

	---------------------------------------------------
	-- Return full generator
	return raiseMountain, combinedMountains
end

-------------------------------------------------------------------------------
-- Register the TUG World Generator with the engine.
Eternus.ScriptManager:NKRegisterGeneratorClass(TUGWorld)
