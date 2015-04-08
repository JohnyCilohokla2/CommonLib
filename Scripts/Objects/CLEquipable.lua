include("Scripts/Core/Common.lua")
include("Scripts/Objects/Equipable.lua")
include("Scripts/Mixins/LiquidStaticProvider.lua")

if (CLEquipable == nil) then
	CLEquipable = Equipable.Subclass("CLEquipable")
end

function CLEquipable:Constructor( args )
	if (args.LiquidProvider) then
		self:Mixin(LiquidStaticProvider, args.LiquidProvider)
	end
end

-------------------------------------------------------------------------------
EntityFramework:RegisterGameObject(CLEquipable)