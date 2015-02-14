include("Scripts/Mixins/LiquidProvider.lua")

-------------------------------------------------------------------------------
LiquidContainer = LiquidProvider.Subclass("LiquidContainer")
LiquidContainer.__mixinoverrides = 
{
	'HasLiquid',
	'GetLiquid'
}

function LiquidContainer:Constructor(args)
	self.m_liquidAmountMax = args.maxAmount or 1
	self.m_liquid = nil
	self.m_liquidAmount = 0
end

function LiquidContainer:HasLiquid(dt, maxAmount, liquidType)
	if (liquidType and liquidType ~= self.m_liquid) then
		return false
	end
	local pulledAmount = math.max(0,math.min(self.m_liquidAmount,maxAmount))
	if (pulledAmount+0.00001 > maxAmount) then
		return true
	else
		return pulledAmount
	end
end

function LiquidContainer:GetLiquid(dt, maxAmount, liquidType, position, player)
	-- player is optional, position is required (this should be where the item is supposed to drop)
	if (liquidType and liquidType ~= self.m_liquid) then
		return nil, 0
	end
	local pulledAmount = math.max(0,math.min(self.m_liquidAmount,maxAmount))
	self.m_liquidAmount = self.m_liquidAmount - pulledAmount
	if (self.m_liquidAmount <= 0) then
		self.m_liquid = nil
		self:OnLiquidContainerEmpty(position, player)
	end
	if (pulledAmount+0.00001 > maxAmount) then
		return self.m_liquid, maxAmount
	else
		return self.m_liquid, pulledAmount
	end
end

-------------------------------------------------------------------------------
function LiquidContainer:NetSerialize( netWriter )
	netWriter:NKWriteString(self.m_liquid)
	netWriter:NKWriteDouble(self.m_liquidAmount)
	netWriter:NKWriteDouble(self.m_liquidAmountMax)
end

-------------------------------------------------------------------------------
function LiquidContainer:NetDeserialize( netReader )
	self.m_liquid = netReader:NKReadString()
	self.m_liquidAmount = netReader:NKReadDouble()
	self.m_liquidAmountMax = netReader:NKReadDouble()
end

-------------------------------------------------------------------------------
function LiquidContainer:Save( outData )
	outData.liquid = self.m_liquid
	outData.liquidAmount = self.m_liquidAmount
end

-------------------------------------------------------------------------------
function LiquidContainer:Restore( inData, version )
	self.m_liquid = inData.liquid or nil
	self.m_liquidAmount = inData.liquidAmount or 0
end

return SurvivalPlacementLogic