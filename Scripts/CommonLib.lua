-- CommonLib
include("Scripts/CL/CL.lua")

-------------------------------------------------------------------------------
if CommonLib == nil then
	CommonLib = EternusEngine.ModScriptClass.Subclass("CommonLib")
end

-------------------------------------------------------------------------------
function CommonLib:Constructor( )
	CL.println("Initializing CommonLib")
	
	self.hitObj = nil
	self.m_connectorCallback = include("Scripts/Callbacks/ConnectorSystem.lua").new()
	
	self.m_configFile = CLConfig.new(self, "Data/config.json")
	self.m_configFile:Load()
	self.m_config = self.m_configFile.m_data
	
	local needsUpdate = false
	if not self.m_config.GUI then
		self.m_config.GUI = {
			debuggingBoxVisible = true
		}
		needsUpdate = true
	end
	if needsUpdate then
		self.m_configFile:Save()
	end
end

function CommonLib:PostLoad( )
	EternusEngine.CallbackManager:RegisterCallback("SurvivalPlacementInput:ProcessGhostObjectOverride",self.m_connectorCallback,"ProcessGhostObjectOverride")
	EternusEngine.CallbackManager:RegisterCallback("SurvivalPlacementLogic:ServerEvent_PlaceAt",self.m_connectorCallback,"ServerEvent_PlaceAt")
end

 -------------------------------------------------------------------------------
function CommonLib:Initialize()
	if Eternus.IsServer then
		Eternus.GameState:RegisterSlashCommand("Heal", self, "Heal")
	end
	
	if Eternus.IsClient then
		include("Scripts/CL/UI/DebuggingBox.lua")
		CEGUI.SchemeManager:getSingleton():createFromFile("CL.scheme")

		Eternus.GameState:RegisterSlashCommand("CommonLib", self, "Info")
		Eternus.GameState:RegisterSlashCommand("JSONTest", self, "JSONTest")
		Eternus.GameState:RegisterSlashCommand("ApplyBuff", self, "ApplyBuff")
		
		self.cl_debuggingBox = CL_DebuggingBox.new("SurvivalLayout.layout")
		self.cl_debuggingBox:SetSize(0.2, 0.2)
		self.cl_debuggingBox:SetPosition(0.8, 0.0, -10, 10)
		self.cl_debuggingBox:SetText("Here! I'm over here! Notice me!")
		
		self.m_inputContext = InputMappingContext.new("CommonLib")
		self.m_inputContext:NKRegisterNamedCommand("CL Toggle Placement Mode", self.m_connectorCallback, "TogglePlacementMode", KEY_ONCE)
		self.m_inputContext:NKRegisterNamedCommand("CL Debugging Box", self, "ToggleDebuggingBox", KEY_ONCE)
	end
end

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
function CommonLib:LocalPlayerReady(player)	
	CL.println("CommonLib:LocalPlayerReady")
	
	player.m_targetAcquiredSignal:Add(function(hitObj)
		if hitObj then
			self.hitObj = hitObj
		end
	end)
	
	player.m_targetLostSignal:Add(function()
		self.hitObj = nil
	end)
end

-------------------------------------------------------------------------------
function CommonLib:Enter()	
	NKWarn("CommonLib>> Enter")
	if Eternus.IsClient then
		if self.m_config.GUI.debuggingBoxVisible then
			self.cl_debuggingBox:Show()
		else
			self.cl_debuggingBox:Hide()
		end
		
		Eternus.InputSystem:NKPushInputContext(self.m_inputContext)
	end
end

-------------------------------------------------------------------------------
function CommonLib:Leave()
	NKWarn("CommonLib>> Enter")
	if Eternus.IsClient then
		if self.m_config.GUI.debuggingBoxVisible then
			self.cl_debuggingBox:Hide()
		end
		
		Eternus.InputSystem:NKRemoveInputContext(self.m_inputContext)
	end
	
	self.m_configFile:Save()
end


local function round(num, idp)
  if idp and idp>0 then
    local mult = 10^idp
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end


-------------------------------------------------------------------------------
-- Called from C++ every update tick
function CommonLib:Process(dt)
	if Eternus.IsClient and self.m_config.GUI.debuggingBoxVisible then
		local out = ""
	
		local wp = Eternus.World:NKGetLocalWorldPlayer()
		if wp then
			local biomeWeights = Eternus.BiomeManager:GetBiomeWeightsForPlayer(wp)
			for key, value in pairs(biomeWeights) do
				local biome = value.biome
				local weight = value.weight
				out = out .. ("Biome: " .. tostring(biome.__classname) .. " " .. tostring(round(weight*100,2)) .. "%\n")
			end
		else
			NKWarn("Couldn't find local world player!")
		end
		
		local wp = Eternus.World:NKGetLocalWorldPlayer()
		if wp then
			local pawn = wp:NKGetPawn()
			if pawn then
				local playerPosition = pawn:NKGetPosition()
				out = out .. ("X: " .. tostring(round(playerPosition:x(),2)) .. "\nY: " .. tostring(round(playerPosition:y(),2)) .. "\nZ: " .. tostring(round(playerPosition:z(),2)) .. "\n")
			end
		end
		
		if self.hitObj then
			out = out .. self.hitObj:GetDisplayName()
			
			
			if (self.hitObj.GetMaxStackCount and self.hitObj:GetMaxStackCount() > 1) then
				out = out .. ("\n" .. self.hitObj:GetStackCount() .." / " .. self.hitObj:GetMaxStackCount())
			end
			
			local traceEquipable = self.hitObj:NKGetEquipable()
			if (traceEquipable ~= nil) then
				out = out .. ("\n{" .. traceEquipable:NKGetCurrentDurability() .." / " .. traceEquipable:NKGetMaxDurability() .. "}")
			end
			
			if (self.hitObj.GetDebuggingText ~= nil) then
				out = out .. ("\n" .. self.hitObj:GetDebuggingText() .."")
			end
			if (self.hitObj.NKGetName ~= nil) then
				out = out .. ("\n(" .. self.hitObj:NKGetName() ..")")
			end
			self.cl_debuggingBox:SetText(out)
		else
			out = out .. "No object selected"
			self.cl_debuggingBox:SetText(out)
		end
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

function CommonLib:ToggleDebuggingBox(down)
	if not down then
		return
	end
	
	self.m_config.GUI.debuggingBoxVisible = not self.m_config.GUI.debuggingBoxVisible
	if self.m_config.GUI.debuggingBoxVisible then
		self.cl_debuggingBox:Show()
	else
		self.cl_debuggingBox:Hide()
	end
end

function CommonLib:Info(userInput, args, commandName, player)
	CL.println("CommonLib:Info")
	player:SendChatMessage("CommonLib:Info\n")
end

function CommonLib:JSONTest(userInput, args, commandName, player)
	if args[1] then --Have a name.
		local fileName = args[1]
		local data = JSON.parseFile(fileName)
		NKWarn("data: " .. EternusEngine.Debugging.Inspect(data) .. "\n")
	end
end

function CommonLib:Heal(userInput, args, commandName, player)
	player:SetHitPoints(100)
	player:_SetEnergy(100)
end

EntityFramework:RegisterModScript(CommonLib)