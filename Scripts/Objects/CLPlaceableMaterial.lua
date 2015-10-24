include("Scripts/PlaceableMaterial.lua")

if (CLPlaceableMaterial == nil) then
	CLPlaceableMaterial = PlaceableMaterial.Subclass("CLPlaceableMaterial")
end

function CLPlaceableMaterial:Constructor( args )
end

-------------------------------------------------------------------------------
EntityFramework:RegisterGameObject(CLPlaceableMaterial)