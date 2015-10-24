-- MyMod
-------------------------------------------------------------------------------
if MyMod == nil then
	MyMod = EternusEngine.ModScriptClass.Subclass("MyMod")
end

 -------------------------------------------------------------------------------
 -- Called once from C++ at engine initialization time
function MyMod:Initialize()
	if Eternus.IsClient then
		self.m_inputContext = InputMappingContext.new("MyMod")
		self.m_inputContext:NKRegisterNamedCommand("MyMod MyFunction", self, "MyFunction", KEY_ONCE)
	end
end

-------------------------------------------------------------------------------
-- Called from C++ when the current game enters 
function MyMod:Enter()	
	if Eternus.IsClient then
		Eternus.InputSystem:NKPushInputContext(self.m_inputContext)
	end
end

-------------------------------------------------------------------------------
-- Called from C++ when the game leaves it current mode
function MyMod:Leave()
	if Eternus.IsClient then
		Eternus.InputSystem:NKRemoveInputContext(self.m_inputContext)
	end
end
EntityFramework:RegisterModScript(MyMod)