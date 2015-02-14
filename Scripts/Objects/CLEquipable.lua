include("Scripts/Core/Common.lua")
include("Scripts/Objects/Equipable.lua")
include("Scripts/Mixins/LiquidStaticProvider.lua")

if (CLEquipable == nil) then
	CLEquipable = Equipable.Subclass("CLEquipable")
end

function CLEquipable:Constructor( args )
	self.m_iconGroup = nil
	if args.iconGroup ~= nil then
		self.m_iconGroup = args.iconGroup
	end
	
	if (args.LiquidProvider) then
		self:Mixin(LiquidStaticProvider, args.LiquidProvider)
	end
end

function CLEquipable:PostLoad()
	CLEquipable.__super.PostLoad(self)
	if (self.m_iconGroup==nil) then
		NKError("Missing Icon Group for CLEquipable "..self:NKGetName().."("..self:NKGetPlaceable():NKGetIconName()..")! Define self.m_iconGroup in the Constructor.")
	end
	self.m_icon 			= self.m_iconGroup.."/"..self:NKGetPlaceable():NKGetIconName()
end

-------------------------------------------------------------------------------
EntityFramework:RegisterGameObject(CLEquipable)