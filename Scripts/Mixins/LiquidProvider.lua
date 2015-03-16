-------------------------------------------------------------------------------
LiquidProvider = EternusEngine.Mixin.Subclass("LiquidProvider")

function LiquidProvider:Constructor(args)
end

function LiquidProvider:HasLiquid(dt, maxAmount, liquidType)
end

function LiquidProvider:GetLiquid(dt, maxAmount, liquidType)
end

function LiquidProvider:OnLiquidContainerEmpty( position, player )
end

return LiquidProvider