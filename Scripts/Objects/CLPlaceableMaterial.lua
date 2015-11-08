include("Scripts/PlaceableMaterial.lua")

if (CLPlaceableMaterial == nil) then
	CLPlaceableMaterial = PlaceableMaterial.Subclass("CLPlaceableMaterial")
end

function CLPlaceableMaterial:Constructor( args )
	if (args.nameOverride) then
		self.m_nameOverride = args.nameOverride
	end
end

function CLPlaceableMaterial:GetDisplayName()
	return self.m_nameOverride or CLPlaceableMaterial.__super.GetDisplayName(self)
end

-------------------------------------------------------------------------------
EntityFramework:RegisterGameObject(CLPlaceableMaterial)