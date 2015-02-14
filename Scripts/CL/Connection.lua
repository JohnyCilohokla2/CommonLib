include("Scripts/Core/Common.lua")

-------------------------------------------------------------------------------
if ConnectionClass == nil then
	ConnectionClass = EternusEngine.Class.Subclass("ConnectionClass")
	ConnectionClass.m_name = "undefined"
	ConnectionClass.m_initialized = false
end

function ConnectionClass:initialize()

end

function ConnectionClass:_initialize()
	if (self.m_initialized==false) then
		self:initialize()
	end
	self.m_initialized = true
end