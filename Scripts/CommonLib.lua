-- CommonLib

include("Scripts/Core/Common.lua")
--include("Scripts/CL/CL.lua")
include("Scripts/CL/UI/DebuggingBox.lua")

-------------------------------------------------------------------------------
CL.println("CommonLib:__Initialize")
if CommonLib == nil then
	CommonLib = EternusEngine.ModScriptClass.Subclass("CommonLib")
	CommonLib.CLMod = CL.mods["CommonLib"]
	CL.println("CommonLib:_Initialize")
end

-------------------------------------------------------------------------------
function CommonLib:Constructor(  )
	CL.println("CommonLib:Constructor")
	CommonLib.CLMod:connectHandler(self)
	--self.m_showInventory2 = true
	--CEGUI.SchemeManager:getSingleton():createFromFile("CL.scheme")
	
end

 -------------------------------------------------------------------------------
 -- Called once from C++ at engine initialization time
function CommonLib:Initialize()
	CL.println("CommonLib:Initialize")

	Eternus.GameState:RegisterSlashCommand("CommonLib", self, "Info")
	Eternus.GameState:RegisterSlashCommand("Args", self, "Args")
	Eternus.GameState:RegisterSlashCommand("Heal", self, "Heal")
	
	--Eternus.GameState:RegisterSlashCommand("tx", self, "TX")
	
	--Eternus.World:NKGetKeybinds():NKRegisterDirectCommand("N", self, "TX", KEY_ONCE)
	
	self.cl_debuggingBox = CL_DebuggingBox.new("SurvivalLayout.layout")
	self.cl_debuggingBox:SetPosition(0.8, 0.0)
	self.cl_debuggingBox:SetSize(0.2, 0.2)
	self.cl_debuggingBox:SetText("Here! I'm over here! Notice me!")
	--self.cl_debuggingBox:SetProgressImage("TUGGame/HealthBarLitRed")
	
	
end

-------------------------------------------------------------------------------
-- Called from C++ when the current game enters 
function CommonLib:Enter()	
	CL.println("CommonLib:Enter")

	self.cl_debuggingBox:Show()
	
	--Eternus.GameState.m_gameModeUI.m_crosshair:show()
	--Eternus.GameState.m_survivalUI.m_backpackView2:Hide()
	--Eternus.InputSystem:NKHideMouse()
	--self.m_showInventory2 = false
end

-------------------------------------------------------------------------------
-- Called from C++ when the game leaves it current mode
function CommonLib:Leave()
	CL.println("CommonLib:Leave")
	self.cl_debuggingBox:Hide()
	
	--Eternus.GameState:RemoveCloseInventory()
	--Eternus.GameState.m_gameModeUI.m_crosshair:show()
	--Eternus.GameState.m_survivalUI.m_backpackView2:Hide()
	--Eternus.InputSystem:NKHideMouse()
	--self.m_showInventory2 = false
end


-------------------------------------------------------------------------------
-- Called from C++ every update tick
function CommonLib:Process(dt)
	--self.cl_debuggingBox:SetProgress(1)
	local traceObj = Eternus.PhysicsWorld:NKGetWorldTracedGameObject()
	if (traceObj~=nil) then
		local traceInstance = traceObj:NKGetInstance()
		if (traceInstance~=nil) then
			local out = traceInstance:NKGetDisplayName();
			
			local traceEquipable = traceInstance:NKGetEquipable()
			
			if (traceInstance:NKCanStack()) then
				out = out .. ("\n" .. traceInstance:NKGetStackCount() .." / " .. traceInstance:NKGetMaxStackCount())
			end
			if (traceEquipable ~= nil) then
				out = out .. ("\n{" .. traceEquipable:NKGetCurrentDurability() .." / " .. traceEquipable:NKGetMaxDurability() .. "}")
			end
			
			--if (traceInstance.GetDebuggingText ~= nil) then
			--	out = out .. (" \n " .. traceInstance:GetDebuggingText() .."")
			--else
			if (traceInstance.GetDebuggingText ~= nil) then
				out = out .. (" \n " .. traceInstance:GetDebuggingText() .."")
			end
			if (traceInstance.NKGetName ~= nil) then
				out = out .. (" \n (" .. traceInstance:NKGetName() ..")")
			end
			CL.mods["CommonLib"].m_handler.cl_debuggingBox:SetText(out)
		end
	else
		CL.mods["CommonLib"].m_handler.cl_debuggingBox:SetText("No object selected")
	end
	local location = vec3.new(49880.0, 155.0, 50015.0);
	
	RDU.NKDisplayLine(location + vec3.new(0.0, 0.0, 0.0), location + vec3.new(0.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(0.0, 4.0, 0.0), location + vec3.new(4.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 4.0, 0.0), location + vec3.new(4.0, 0.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 0.0, 0.0), location + vec3.new(0.0, 0.0, 0.0), RDU.eRED)
	
	location = vec3.new(49884.0, 155.0, 50018.0);
	
	RDU.NKDisplayLine(location + vec3.new(0.0, 0.0, 0.0), location + vec3.new(0.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(0.0, 4.0, 0.0), location + vec3.new(4.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 4.0, 0.0), location + vec3.new(4.0, 0.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 0.0, 0.0), location + vec3.new(0.0, 0.0, 0.0), RDU.eRED)
	
	self.cl_debuggingBox:SetSize(0.2, 0.2)
	self.cl_debuggingBox:SetPosition(0.8, 0.0, -10, 10)
end

function CommonLib:Render()
end


function CommonLib:Info(args)
	CL.println("CommonLib:Info")
end

function CommonLib:Heal(args)
	local player = Eternus.GameState:GetPlayerInstance()
	player.m_health = player.m_maxHealth
	player.m_stamina = player.m_maxStamina
	player.m_energy = player.m_maxEnergy
end

function CommonLib:Args(args)
	local out = ""
	table.foreach(args, function(k,v) out = out .. "" .. k .. "=" .. v .. ", " end)
	CL.println("CommonLib:Info")
	self.cl_debuggingBox:SetText(out)
end

--[[function CommonLib:TX(down)
	if down then
		return
	end
	CL.println("CommonLib:TX")
	Eternus.GameState:ToggleCustomInventory( Eternus.GameState.m_survivalUI.m_backpackView2 )
end]]

EntityFramework:RegisterModScript(CommonLib)