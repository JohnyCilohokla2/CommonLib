include("Scripts/Core/Common.lua")
include("Scripts/Objects/PlaceableObject.lua")
include("Scripts/Mixins/LiquidStaticProvider.lua")

if (CLPlaceableObject == nil) then
	CLPlaceableObject = PlaceableObject.Subclass("CLPlaceableObject")
end

function CLPlaceableObject:Constructor( args )
	self.m_iconGroup = nil
	if args.iconGroup ~= nil then
		self.m_iconGroup = args.iconGroup
	end
	
	if (args.LiquidProvider) then
		self:Mixin(LiquidStaticProvider, args.LiquidProvider)
	end
end

function CLPlaceableObject:PostLoad()
	CLPlaceableObject.__super.PostLoad(self)
	if (self.m_iconGroup==nil) then
		NKError("Missing Icon Group for CLPlaceableObject "..self:NKGetName().."("..self:NKGetPlaceable():NKGetIconName()..")! Define self.m_iconGroup in the Constructor.")
	end
	self.m_icon 			= self.m_iconGroup.."/"..self:NKGetPlaceable():NKGetIconName()
end

-------------------------------------------------------------------------------
EntityFramework:RegisterGameObject(CLPlaceableObject)