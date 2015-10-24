include("Scripts/Objects/PlaceableObject.lua")
include("Scripts/Mixins/LiquidStaticProvider.lua")

if (CLPlaceableObject == nil) then
	CLPlaceableObject = PlaceableObject.Subclass("CLPlaceableObject")
end

function CLPlaceableObject:Constructor( args )
	if (args.LiquidProvider) then
		self:Mixin(LiquidStaticProvider, args.LiquidProvider)
	end
end

-------------------------------------------------------------------------------
EntityFramework:RegisterGameObject(CLPlaceableObject)