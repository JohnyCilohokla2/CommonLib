include("Scripts/Mixins/LiquidProvider.lua")

-------------------------------------------------------------------------------
LiquidStaticProvider = LiquidProvider.Subclass("LiquidProvider")
LiquidStaticProvider.__mixinoverrides = 
	{
		'HasLiquid',
		'GetLiquid'
	}
	
function LiquidStaticProvider:Constructor(args)
	self.m_liquid = args.liquid
	self.m_liquidAmount = args.amount
end

function LiquidStaticProvider:HasLiquid(dt, maxAmount, liquidType)
	if (not dt) then
		return false
	end
	if (liquidType and liquidType ~= self.m_liquid) then
		return false
	end
	local pulledAmount = math.max(0,math.min(self.m_liquidAmount * dt,maxAmount))
	if (pulledAmount == maxAmount) then
		return true
	else
		return pulledAmount
	end
end

function LiquidStaticProvider:GetLiquid(dt, maxAmount, liquidType)
	if ((not dt) or (liquidType and liquidType ~= self.m_liquid)) then
		return nil, 0
	end
	local pulledAmount = math.max(0,math.min(self.m_liquidAmount * dt,maxAmount))
	return self.m_liquid, pulledAmount
end

return LiquidStaticProvider