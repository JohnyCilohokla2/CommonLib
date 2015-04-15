-- CommonLib


-------------------------------------------------------------------------------
CL.println("CommonLib:__Initialize")
if CommonLib == nil then
	CommonLib = EternusEngine.ModScriptClass.Subclass("CommonLib")
	CL.println("CommonLib:_Initialize")
end

-------------------------------------------------------------------------------
function CommonLib:Constructor( )
	CL.println("CommonLib:Constructor")
	
	self.hitObj = nil
end

function CommonLib:initializeHooks( )
	self.m_hookList = {"hook.lua"}
end

 -------------------------------------------------------------------------------
 -- Called once from C++ at engine initialization time
function CommonLib:Initialize()
	include("Scripts/CL/UI/DebuggingBox.lua")
	CEGUI.SchemeManager:getSingleton():createFromFile("CL.scheme")
	
	CL.println("CommonLib:Initialize")

	Eternus.GameState:RegisterSlashCommand("CommonLib", self, "Info")
	Eternus.GameState:RegisterSlashCommand("Args", self, "Args")
	Eternus.GameState:RegisterSlashCommand("Heal", self, "Heal")
	
	Eternus.GameState:RegisterSlashCommand("ApplyBuff", self, "ApplyBuff")
	
	--Eternus.GameState:RegisterSlashCommand("tx", self, "TX")
	
	--Eternus.World:NKGetKeybinds():NKRegisterDirectCommand("N", self, "TX", KEY_ONCE)
	
	self.cl_debuggingBox = CL_DebuggingBox.new("SurvivalLayout.layout")
	self.cl_debuggingBox:SetSize(0.2, 0.2)
	self.cl_debuggingBox:SetPosition(0.8, 0.0, -10, 10)
	self.cl_debuggingBox:SetText("Here! I'm over here! Notice me!")
	--self.cl_debuggingBox:SetProgressImage("TUGGame/HealthBarLitRed")
	
	CL:RegisterCrafting(Eternus.CraftingSystem)
	
	
end

include("Scripts/Buffs/EnergyBuff.lua")
include("Scripts/Buffs/FireDebuff.lua")
include("Scripts/Buffs/FrozenDebuff.lua")
include("Scripts/Buffs/PoisonBombBuff.lua")
include("Scripts/Buffs/RunSpeedBuff.lua")
include("Scripts/Buffs/RunSpeedSwordBuff.lua")

function CommonLib:ApplyBuff(args)
	if args[1] then --Have a name.
		local buffName = args[1]
		
		if EternusEngine.BuffManager.m_buffs[buffName] then
			local value = -1
			if args[2] then
				value = tonumber(args[2])
			end
			if value or value >= 0 then
				local duration = -1
				if args[3] then
					duration = tonumber(args[3])
				end
				if duration or duration >= 0 then
					local newBuff = EternusEngine.BuffManager:CreateBuff(buffName, {duration = duration, value = value, stacks = false})
					Eternus.GameState.player:ApplyBuff(newBuff)
					Eternus.CommandService:NKAddLocalText("Applying buff " .. buffName .. "!\n")
				else
					Eternus.CommandService:NKAddLocalText("Invalid duration!\n")
				end
			else
				Eternus.CommandService:NKAddLocalText("Invalid value!\n")
			end
		else
			Eternus.CommandService:NKAddLocalText("" .. buffName .. " doesn't exist!\n")
		end
	end
	Eternus.CommandService:NKAddLocalText("Syntax: /ApplyBuff [name] [value] [duration]\n")
	return true
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
	
	
	local player = Eternus.GameState:GetLocalPlayer():NKGetInstance()
	
	player.m_targetAcquiredSignal:Add(function(hitObj)
		if hitObj and hitObj:NKGetInstance() then
			self.hitObj = hitObj
		end
	end)
	
	player.m_targetLostSignal:Add(function()
		self.hitObj = nil
	end)
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
	
	if self.hitObj and self.hitObj:NKGetInstance() then
		local traceInstance = self.hitObj:NKGetInstance()
		local out = traceInstance:NKGetDisplayName();
		
		local traceEquipable = traceInstance:NKGetEquipable()
		
		if (traceInstance.GetMaxStackCount and traceInstance:GetMaxStackCount() > 1) then
			out = out .. ("\n" .. traceInstance:GetStackCount() .." / " .. traceInstance:GetMaxStackCount())
		end
		if (traceEquipable ~= nil) then
			out = out .. ("\n{" .. traceEquipable:NKGetCurrentDurability() .." / " .. traceEquipable:NKGetMaxDurability() .. "}")
		end
		if (traceInstance.GetDebuggingText ~= nil) then
			out = out .. (" \n " .. traceInstance:GetDebuggingText() .."")
		end
		if (traceInstance.NKGetName ~= nil) then
			out = out .. (" \n (" .. traceInstance:NKGetName() ..")")
		end
		self.cl_debuggingBox:SetText(out)
	else
		self.cl_debuggingBox:SetText("No object selected, lol")
		self.hitObj = nil
	end
	
	--[[local location = vec3.new(49880.0, 155.0, 50015.0);
	
	RDU.NKDisplayLine(location + vec3.new(0.0, 0.0, 0.0), location + vec3.new(0.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(0.0, 4.0, 0.0), location + vec3.new(4.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 4.0, 0.0), location + vec3.new(4.0, 0.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 0.0, 0.0), location + vec3.new(0.0, 0.0, 0.0), RDU.eRED)
	
	location = vec3.new(49884.0, 155.0, 50018.0);
	
	RDU.NKDisplayLine(location + vec3.new(0.0, 0.0, 0.0), location + vec3.new(0.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(0.0, 4.0, 0.0), location + vec3.new(4.0, 4.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 4.0, 0.0), location + vec3.new(4.0, 0.0, 0.0), RDU.eRED)
	RDU.NKDisplayLine(location + vec3.new(4.0, 0.0, 0.0), location + vec3.new(0.0, 0.0, 0.0), RDU.eRED)
	]]
end

function CommonLib:Render()
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

CL.println(" [EntityFramework] CommonLib")
EntityFramework:RegisterModScript(CommonLib)