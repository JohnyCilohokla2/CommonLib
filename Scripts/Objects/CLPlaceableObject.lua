include("Scripts/Objects/PlaceableObject.lua")
include("Scripts/Mixins/LiquidStaticProvider.lua")

if (CLPlaceableObject == nil) then
	CLPlaceableObject = PlaceableObject.Subclass("CLPlaceableObject")
end

function CLPlaceableObject:Constructor( args )
	if (args.LiquidProvider) then
		self:Mixin(LiquidStaticProvider, args.LiquidProvider)
	end
	if (args.nameOverride) then
		self.m_nameOverride = args.nameOverride
	end
end

function CLPlaceableObject:GetDisplayName()
	return self.m_nameOverride or CLPlaceableObject.__super.GetDisplayName(self)
end

-------------------------------------------------------------------------------
EntityFramework:RegisterGameObject(CLPlaceableObject)