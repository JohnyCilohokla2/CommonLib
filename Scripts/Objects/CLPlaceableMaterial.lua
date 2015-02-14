include("Scripts/Core/Common.lua")
include("Scripts/PlaceableMaterial.lua")

if (CLPlaceableMaterial == nil) then
	CLPlaceableMaterial = PlaceableMaterial.Subclass("CLPlaceableMaterial")
end

function CLPlaceableMaterial:Constructor( args )
	self.m_iconGroup = nil
	if args.iconGroup ~= nil then
		self.m_iconGroup = args.iconGroup
	end
end

function CLPlaceableMaterial:PostLoad()
	CLPlaceableMaterial.__super.PostLoad(self)
	if (self.m_iconGroup==nil) then
		NKError("Missing Icon Group for CLPlaceableMaterial "..self:NKGetName().."("..self:NKGetPlaceable():NKGetIconName()..")! Define self.m_iconGroup in the Constructor.")
	end
	self.m_icon 			= self.m_iconGroup.."/"..self:NKGetPlaceable():NKGetIconName()
end

-------------------------------------------------------------------------------
EntityFramework:RegisterGameObject(CLPlaceableMaterial)