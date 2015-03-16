-------------------------------------------------------------------------------
if SignalInterface == nil then
	SignalInterface = EternusEngine.Mixin.Subclass("SignalInterface")
end

function SignalInterface:OnPlace()
	NKPrint("SignalInterface:OnPlace()\n")
end
