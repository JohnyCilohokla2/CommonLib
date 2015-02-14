-- TUGGameMode
include("Scripts/UI/TUGGameModeUIView.lua")
include("Scripts/Characters/LocalPlayer.lua")
include("Scripts/Core/Common.lua")
include("Scripts/CraftingSystem.lua")
include("Scripts/Objects/Scoreboard.lua")

include("Scripts/CL/CL.lua")

local out 				= Eternus.Output

-------------------------------------------------------------------------------
if TUGGameMode == nil then
	TUGGameMode = EternusEngine.GameStateClass.Subclass("TUGGameMode")
	TUGGameMode.m_activeCamera = nil
	TUGGameMode.m_primaryHeld = false
	TUGGameMode.m_slashCommands = {}
	TUGGameMode.m_prevFrame = false
end

TUGGameMode.DefaultCrosshair		= "TUGGame/Crosshair"
TUGGameMode.CrosshairSquare 		= "TUGGame/CrosshairSquare"
TUGGameMode.CrosshairSquareRounded	= "TUGGame/CrosshairSquareRounded"
TUGGameMode.CrosshairSphere			= "TUGGame/CrosshairSphere"

-------------------------------------------------------------------------------
-- This is called before creating a new gamestate script when you create a new game
function TUGGameMode:Cleanup()

end

 -------------------------------------------------------------------------------
 -- Called once from C++ at engine initialization time.
function TUGGameMode:Initialize()
	-- Seed the rng.
	math.randomseed( os.time() )
	self.m_stateActive = false
	self.m_appHasFocus = true
	self.m_restoreMouse= false
	--Setup the cameras
	self.m_fpcamera   = FirstPersonCamera.new()
	self.m_tpcamera   = ThirdPersonCamera.new()
	self.m_freecamera = FreeCamera.new()

	-- Set up the scoreboard
	if Eternus.IsServer then
		-- Create the scoreboard object
		local obj = Eternus.GameObjectSystem:NKCreateNetworkedGameObject("Scoreboard", true, true)

		-- Force syncronization to all clients all the time
		obj:NKGetNet():NKForceGlobalRelevancy(true)
	end

	-- TODO: NetworkingDev
	self.m_activeCamera = self.m_fpcamera
	--self.state:NKSetActiveCamera(self.m_activeCamera)

	-- Setup the input callbacks
	-- Moving these to the enter function so we know we
	-- have a valid input system.
	--self:SetupInputSystem();

	-- TODO: NetworkingDev
	-- EternusEngine.UI.Layers.Gameplay:show()
	
	-- Set up slash commands
	Eternus.CommandService:NKRegisterChatCommand("testcommand", "CommandExample")
	Eternus.CommandService:NKRegisterChatCommand("printhealth", "PrintPlayerHealth")
	Eternus.CommandService:NKRegisterChatCommand("sethealth", "SetPlayerHealth")
	Eternus.CommandService:NKRegisterChatCommand("inspect", "Inspect")
	
	-- Make the crafting system.
	self.m_craftingSystem = CraftingSystem.new()
	self.m_craftingSystem:ParseRecipeFile("Data/Crafting/Core_crafting.txt")
	
	CL:RegisterCrafting(self.m_craftingSystem)


	self:SetupInputSystem()
	
	CL:InitializeTUGMods()
	return 0;
end

-------------------------------------------------------------------------------
function TUGGameMode:AppFocusGained()
	self.m_appHasFocus = true
end

-------------------------------------------------------------------------------
function TUGGameMode:AppFocusLost()
	self.m_appHasFocus = false
end

-------------------------------------------------------------------------------
function TUGGameMode:IsAppInFocus()
	return self.m_appHasFocus
end

-------------------------------------------------------------------------------
-- Example function for slash commands.
-- userInput - The full string the player typed, command and all.
-- args - The parsed args of the command.
function TUGGameMode:CommandExample(userInput, args)
	NKPrint("\nNow printing args:\n")
	for key,value in pairs(args) do
		NKPrint(value .. "\n")
	end
	NKPrint("Finished printing.\n")
	return true
end

function TUGGameMode:PrintPlayerHealth(userInput, args)
	self.player:PrintHealth()
end

function TUGGameMode:Inspect( userInput, args )
	local obj = Eternus.PhysicsWorld:NKGetWorldTracedGameObject()
	if (obj) then
		local objInst = obj:NKGetInstance()
		if (objInst) then
			local var = args[1]
			if (var ~= nil) then
				local iVar = objInst[var]
				Eternus.CommandService:NKAddLocalText(var .. ": " .. tostring(iVar) .. "\n")
			else
				NKPrint("/inspect <variable name to inspect>\n")
				NKPrint("Inspecting: " .. obj:NKGetName() .. "\n")
				self:PrintTable(objInst, obj:NKGetName(), 0)
			end
		else
			NKPrint("Object " .. obj:NKGetName() .. " has no script.\n")
		end
	else
		NKPrint("Look at an object then try again.\n")
	end
end

-------------------------------------------------------------------------------
-- Debug thingy for printing a table as inefficiently as possible.
function TUGGameMode:PrintTable(tab, tabName, indentLevel)
	NKPrint(self:GetIndent(indentLevel - 1) .. tostring(tabName) .. "\n" .. self:GetIndent(indentLevel - 1) .. "{\n")
	for key, value in pairs(tab) do
		local firstKeyChars = string.sub(tostring(key), 0, 2)
		--NKError("FIRSTTWOCHARS: :" .. firstKeyChars .. ":\nKey: "  .. tostring(key) .. "\n")
		
		if (firstKeyChars ~= "__") then
			if (type(value) == "table") then
				--NKPrint("--=Key: " .. tostring(key) .. "\n")
				self:PrintTable(value, key, indentLevel + 1)
			elseif (type(value) ~= "function") then
				NKPrint(self:GetIndent(indentLevel) .. tostring(key) .. ": " .. tostring(value) .. "\n")
			end
		end
	end
	NKPrint(self:GetIndent(indentLevel-1) .. "}\n")
end

-------------------------------------------------------------------------------
-- Debug thingy for getting an indent as inefficiently as possible.
function TUGGameMode:GetIndent(level)
	local indent = ""
	if (level >= 0) then
		for i = 0, level, 1 do
			indent = indent .. "\t"
		end
	end
	
	return indent
end

function TUGGameMode:SetPlayerHealth(userInput, args)
	
	if (args[1] ~= nil) then
	NKError("Setting " .. args[1])
		self.player.m_health = tonumber(args[1])
	end
end

function TUGGameMode:Server_CreatePawn( clientConnection )
	local gameobject = nil

	if clientConnection:NKIsLocalPlayer() then
		gameobject = Eternus.GameObjectSystem:NKCreateNetworkedGameObject("Local Player", true, false)
	else
		Eternus.CommandService:NKSendNetworkText(clientConnection:NKGetPlayerName() .. " is joining the server.")
		gameobject = Eternus.GameObjectSystem:NKCreateNetworkedGameObject("Network Player", true, false)
	end

	if not gameobject then
		out:PrintToChannel(DebugOutput.eDebugChannelLua, DebugOutput.ePriorityError, "Unable to create player pawn!\n")
	else
		
		gameobject:NKGetInstance().m_connection = clientConnection 
		gameobject:NKGetInstance():InitializePawn()
	end
	
	return gameobject
end

function TUGGameMode:Client_LocalPawnReady( conn )
	self.player = conn:NKGetPawn():NKGetInstance()

	self.player.m_controller = self.player:NKGetCharacterController()
end

function TUGGameMode:Server_EnterWorld( clientConnection )
	clientConnection:NKGetPawn():NKPlaceInWorld(false, false)

	gScoreboard:AddPlayer(clientConnection:NKGetPlayerName(), clientConnection:NKGetLastPing(), clientConnection)
end

function TUGGameMode:Client_EnterWorld( conn )

	if self.player.Initialize then
		self.player:Initialize(self)
	end
	
	conn:NKGetPawn():NKPlaceInWorld(false, false)

	conn:NKGetPawn():NKSetOrientation(quat.new(0.0, 0.0, -1.0, 0.0))
end

function TUGGameMode:Server_LeaveWorld( clientConnection )
	Eternus.CommandService:NKSendNetworkText(clientConnection:NKGetPlayerName() .. " has left the server.")
	clientConnection:NKGetPawn():NKRemoveFromWorld(true, false)
	gScoreboard:RemovePlayer(clientConnection:NKGetPlayerName())
end

function TUGGameMode:GoToMenu( down )
	NKPrint("GoToMenu Called.")
	if down then
		return
	end
	Eternus.GameState.state:NKRequestSwitchGameStateToMenu(true)
end

 -------------------------------------------------------------------------------
 -- Register input for TUGGameMode mode.
function TUGGameMode:SetupInputSystem()

	Eternus.World:NKGetKeybinds():NKRegisterNamedCommand("Toggle Camera Mode", self, "ToggleCameraMode", KEY_ONCE)
	Eternus.World:NKGetKeybinds():NKRegisterNamedCommand("Show Players", self, "ShowPlayers", KEY_FLOOD)
	Eternus.World:NKGetKeybinds():NKRegisterNamedCommand("Toggle UI", self, "ToggleUI", KEY_ONCE)
	Eternus.World:NKGetKeybinds():NKRegisterNamedCommand("Return to Menu", self, "GoToMenu", KEY_ONCE)

	Eternus.CommandService:NKRegisterChatCommand("time"				, "ChatCommandTime"				)
	Eternus.CommandService:NKRegisterChatCommand("timescale"		, "ChatCommandTimeScale"		)
	Eternus.CommandService:NKRegisterChatCommand("viewdistance"		, "ChatCommandViewDistance"		)
	Eternus.CommandService:NKRegisterChatCommand("spawn"			, "ChatCommandSpawn"			)
	Eternus.CommandService:NKRegisterChatCommand("volume"			, "ChatCommandVolume"			)
	Eternus.CommandService:NKRegisterChatCommand("ambientvolume"	, "ChatCommandAmbientVolume"	)
	Eternus.CommandService:NKRegisterChatCommand("gammacorrection"	, "ChatCommandGammaCorrection"	)
	Eternus.CommandService:NKRegisterChatCommand("objectdistance"	, "ChatCommandObjectDistance"	)
	Eternus.CommandService:NKRegisterChatCommand("sound"			, "ChatCommandSound"			)
	Eternus.CommandService:NKRegisterChatCommand("takedamage"		, "ChatCommandTakeDamage"		)
	Eternus.CommandService:NKRegisterChatCommand("playsound"		, "ChatCommandPlaySound"		)
	Eternus.CommandService:NKRegisterChatCommand("unstuck"			, "ChatCommandUnstuck"			)
	Eternus.CommandService:NKRegisterChatCommand("setstat"			, "ChatCommandSetStat"			)
	Eternus.CommandService:NKRegisterChatCommand("buff"				, "ChatCommandBuff"				)

	
	-- Server Only Commands
	if Eternus.IsExclusiveServer then
		Eternus.CommandService:NKRegisterChatCommand("maxviewdistance"	, "ChatCommandMaxViewDistance"	)
		Eternus.CommandService:NKRegisterChatCommand("kick"				, "ChatCommandKick"				)
		Eternus.CommandService:NKRegisterChatCommand("banlist"			, "ChatCommandBanList"			)
		Eternus.CommandService:NKRegisterChatCommand("ban"				, "ChatCommandBan"				)
		Eternus.CommandService:NKRegisterChatCommand("unban"			, "ChatCommandUnban"			)
		Eternus.CommandService:NKRegisterChatCommand("clearbans"		, "ChatCommandClearBans"		)
		Eternus.CommandService:NKRegisterChatCommand("maxplayers"		, "ChatCommandMaxPlayers"		)
		Eternus.CommandService:NKRegisterChatCommand("allowconnections"	, "ChatCommandAllowConnections"	)
	end
	
	if Eternus.IsExclusiveServer or Eternus.IsExclusiveClient then
		Eternus.CommandService:NKRegisterChatCommand("ping"				, "ChatCommandPing"				)
	end

	-- Debugging Commands
	Eternus.CommandService:NKRegisterChatCommand("debugging", "DebuggingCommand")
	Eternus.CommandService:NKRegisterChatCommand("logging", "LoggingCommand")
	Eternus.CommandService:NKRegisterChatCommand("teleport", "TeleportCommand")
	Eternus.CommandService:NKRegisterChatCommand("suppresserrors", "SuppressErrorsCommand")
	Eternus.CommandService:NKRegisterChatCommand("se", "SuppressErrorsCommand")
end

function TUGGameMode:SuppressErrorsCommand(userInput, args)
	if args[1] then
		if args[1] == "true" then
			Eternus.Output:NKSetErrorsSuppressed(true)
			Eternus.CommandService:NKAddLocalText("Debugging errors will be suppressed to console (red text).\n")
		elseif args[1] == "false" then
			Eternus.Output:NKSetErrorsSuppressed(false)
			Eternus.CommandService:NKAddLocalText("Debugging errors will be displayed in a pop-up.\n")
		else
			Eternus.CommandService:NKAddLocalText("Invalid input. Usage: '/<se | suppresserrors> <true | false>'\n")
		end
	else
		Eternus.CommandService:NKAddLocalText("Invalid input. Usage: '/<se | suppresserrors> <true | false>'\n")
	end
end

function TUGGameMode:DebuggingCommand(userInput, args)
	if args[1] then 
		if args[1] == "true" then
			EternusEngine.Debugging.Enabled = true
		elseif args[1] == "false" then 
			EternusEngine.Debugging.Enabled = false
		elseif args[1] == "generation" then 
			EternusEngine.Debugging.Generation = not EternusEngine.Debugging.Generation
		end
	else 
		EternusEngine.Debugging.Enabled = not EternusEngine.Debugging.Enabled
	end
end

function TUGGameMode:LoggingCommand(userInput, args)
	if args[1] then 
		if args[1] == "true" then
			Eternus.Debugging.Logging = true
		elseif args[1] == "false" then 
			Eternus.Debugging.Logging = false
		end
	else 
		Eternus.Debugging.Logging = not Eternus.Debugging.Logging
	end

	if Eternus.Debugging.Logging then 
		NKPrint("<Debug Logging Enabled>\n")
	else
		NKPrint("<Debug Logging Disabled>\n")
	end
end

function TUGGameMode:TeleportCommand(userInput, args)
	if args[1] and args[2] and args[3] then
		self.player:TeleportCommand(vec3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3])))
	end
end

function TUGGameMode:ChatCommandBuff( userInput, args )
	if (args[3] == nil) then
		Eternus.CommandService:NKAddLocalText("/buff <buffName> <modifierValue> <duration> <add | multiply> <value | min | max> <stacks>\n")
		return
	end
	
	local buffName = args[1]
	local modifierValue = tonumber(args[2])
	local duration = tonumber(args[3])
	local actionString = args[4]
	local typeString = args[5]
	local stacks = args[6]
	local action = StatModifier.EStatModAction.eAdd
	local type = StatModifier.EStatModType.eValue
	
	if (modifierValue == nil) then
		Eternus.CommandService:NKAddLocalText("modifierValue must be a number.\n/buff <buffName> <modifierValue> <duration> <add | multiply> <value | min | max> <stacks>\n")
		return
	end
	
	if (duration == nil) then
		Eternus.CommandService:NKAddLocalText("duration must be a number.\n/buff <buffName> <modifierValue> <duration> <add | multiply> <value | min | max> <stacks>\n")
		return
	end
	
	if (actionString ~= nil) then
		if (actionString ~= "add" and actionString ~= "multiply") then
			Eternus.CommandService:NKAddLocalText("action must be either add or multiply.\n/buff <buffName> <modifierValue> <duration> <add | multiply> <value | min | max> <stacks>\n")
			return
		else
			if (actionString == "add") then
				action = StatModifier.EStatModAction.eAdd
			else
				action = StatModifier.EStatModAction.eMultiply
			end
		end
	else
		actionString = "Add"
		action = StatModifier.EStatModAction.eAdd
	end
	
	if (typeString ~= nil) then
		if (typeString ~= "value" and typeString ~= "min" and typeString ~= "max") then
			Eternus.CommandService:NKAddLocalText("type must be either value, min, or max.\n/buff <buffName> <modifierValue> <duration> <add | multiply> <value | min | max> <stacks>\n")
		else
			if (typeString == "value") then
				type = StatModifier.EStatModType.eValue
			elseif (typeString == "min") then
				type = StatModifier.EStatModType.eMin
			else
				type = StatModifier.EStatModType.eMax
			end
		end
	else
		typeString = "Value"
		type = StatModifier.EStatModType.eValue
	end
	
	if (stacks ~= nil) then
		if (stacks == "true") then
			stacks = true
		elseif (stacks == "false") then
			stacks = false
		else
			Eternus.CommandService:NKAddLocalText("stacks must be either true or false.\n/buff <buffName> <modifierValue> <duration> <add | multiply> <value | min | max> <stacks>\n")
			return
		end
	else
		stacks = true
	end
	
	local buffArgs = {}
	buffArgs.name = buffName
	buffArgs.duration = duration
	buffArgs.stat = "TestStat"
	buffArgs.value = modifierValue
	buffArgs.action = action
	buffArgs.type = type
	buffArgs.stacks = stacks
	NKPrint("\n---======---\nApplying buff to player.\nName: " .. buffName .. "\nDuration: " .. tostring(duration) .. "\nValue: " .. tostring(modifierValue) .. "\nAction: " .. actionString .. "\nType: " .. typeString .. "\nStacks: " .. tostring(stacks) .. "\n---======---\n")
	local newBuff = Buff.new(buffArgs)
	self.player:ApplyBuff(newBuff)
end

-------------------------------------------------------------------------------
-- Chat command for getting a player unstuck
function TUGGameMode:ChatCommandUnstuck( userInput, args )
	Eternus.CommandService:NKAddLocalText("Attempting to get you unstuck!\n")
	
	local pos = self.player:NKGetPosition() + (self.player:GetForwardVector():mul_scalar(-5.0))

	self.player:NKSetPosition(pos)

end

-------------------------------------------------------------------------------
-- Chat command for displaying ping to server/all connected players.
function TUGGameMode:ChatCommandSetStat( userInput, args )
	if not args[2] then
		Eternus.CommandService:NKAddLocalText("Function: /setstat <health | stamina | energy> <#>\n")
		return
	end
	
	local stat = args[1]
	local newVal = tonumber(args[2])
	if not newVal then
		Eternus.CommandService:NKAddLocalText("Second parameter must be a number.\nFunction: /setstat <health | stamina | energy> <#>\n")
		return
	end
	
	if stat == "health" then
		self.player:_SetHealth(newVal)
	elseif stat == "stamina" then
		--self.player:_SetStamina
		Eternus.CommandService:NKAddLocalText("Stamina setting not yet implemented.\n")
	elseif stat == "energy" then
		self.player:_SetEnergy(newVal)
	end
end


-------------------------------------------------------------------------------
-- Chat command for displaying ping to server/all connected players.
function TUGGameMode:ChatCommandPing( userInput, args )
	if Eternus.IsExclusiveServer then -- Ping all connected players.
		local pingString = ""
		local players = Eternus.World:NKGetAllWorldPlayers()
		for key,value in pairs(players) do
			pingString = pingString .. value:NKGetPlayerName() .. ": " .. tostring(value:NKGetAveragePing()) .. "\n"
		end
		Eternus.CommandService:NKAddLocalText("==== Player Pings: ====\n\n" .. pingString .. "\n=======================\n\n")
	elseif Eternus.IsClient then
		local player = Eternus.World:NKGetLocalWorldPlayer()
		Eternus.CommandService:NKAddLocalText("Your ping is: " .. tostring(player:NKGetAveragePing()) .. "\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for kicking players from the server
function TUGGameMode:ChatCommandKick( userInput, args )
	if Eternus.IsExclusiveServer then
		if not args[1] then
			Eternus.CommandService:NKAddLocalText("Function: /kick <player name>\n")
			return
		end

		local playerName = args[1]

		local ret = Eternus.Net:NKClosePlayerConnection(playerName)

		if ret then
			Eternus.CommandService:NKSendNetworkText("Player " .. playerName .. " has been kicked from the server!\n")
		else
			Eternus.CommandService:NKAddLocalText("Problem attempting to kick player '" .. playerName .. "'!\n")
		end

	else
		Eternus.CommandService:NKAddLocalText("You cannot run a server only command!\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for getting the list of bans
function TUGGameMode:ChatCommandBanList( userInput, args )
	if Eternus.IsExclusiveServer then

		local ret = Eternus.Net:NKGetBanList()

		Eternus.CommandService:NKAddLocalText("Current Ban List\n")
		Eternus.CommandService:NKAddLocalText(ret)

	else
		Eternus.CommandService:NKAddLocalText("You cannot run a server only command!\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for banning players from the server
function TUGGameMode:ChatCommandBan( userInput, args )
	if Eternus.IsExclusiveServer then
		if not args[1] then
			Eternus.CommandService:NKAddLocalText("Function: /ban <player name>\n")
			return
		end

		local playerName = args[1]

		local ret = Eternus.Net:NKBanPlayer(playerName)

		if ret then
			Eternus.CommandService:NKSendNetworkText("Player " .. playerName .. " has been banned from the server!\n")
		else
			Eternus.CommandService:NKAddLocalText("Problem attempting to ban player '" .. playerName .. "'!\n")
		end
		
	else
		Eternus.CommandService:NKAddLocalText("You cannot run a server only command!\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for unbanning players from the server
function TUGGameMode:ChatCommandUnban( userInput, args )
	if Eternus.IsExclusiveServer then
		if not args[1] then
			Eternus.CommandService:NKAddLocalText("Function: /unban <ip> (hint: use /banlist to see current bans)\n")
			return
		end

		local ip = args[1]

		local ret = Eternus.Net:NKRemoveBan(ip)

		if ret then
			Eternus.CommandService:NKAddLocalText("IP " .. ip .. " has been unbanned from the server!\n")
		else
			Eternus.CommandService:NKAddLocalText("Problem attempting to unban ip '" .. ip .. "'!\n")
		end
		
	else
		Eternus.CommandService:NKAddLocalText("You cannot run a server only command!\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for clearing banned players from the server
function TUGGameMode:ChatCommandClearBans( userInput, args )
	if Eternus.IsExclusiveServer then
	
		Eternus.Net:NKClearAllBans()

	else
		Eternus.CommandService:NKAddLocalText("You cannot run a server only command!\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for changing max players on the server
function TUGGameMode:ChatCommandMaxPlayers( userInput, args )
	if Eternus.IsExclusiveServer then
		if not args[1] then
			local maxPlayers = tostring(Eternus.Net:NKGetMaxPlayers())
			Eternus.CommandService:NKAddLocalText("Max allowed players: " .. maxPlayers .. "\n")
			return
		end

		local maxPlayers = (args[1])
		
		Eternus.Net:NKSetMaxPlayers(maxPlayers)
		
		maxPlayers = tostring(Eternus.Net:NKGetMaxPlayers())

		Eternus.CommandService:NKAddLocalText("Max allowed players set to " .. maxPlayers .. "\n")

	else
		Eternus.CommandService:NKAddLocalText("You cannot run a server only command!\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for enabling and disabling incoming connections
function TUGGameMode:ChatCommandAllowConnections( userInput, args )
	if Eternus.IsExclusiveServer then
		if not args[1] then
			Eternus.CommandService:NKAddLocalText("Function: /allowconnections <true | false>\n")
			return
		end

		if(args[1] == "true") then
			Eternus.Net:NKAllowConnections(true)
		elseif(args[1] == "false") then
			Eternus.Net:NKAllowConnections(false)
		end

	else
		Eternus.CommandService:NKAddLocalText("You cannot run a server only command!\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for playing sounds.
function TUGGameMode:ChatCommandPlaySound( userInput, args )
	local volume = 1
	if args[2] then
		local newVol = tonumber(args[2])
		if newVol then
			volume = newVol
		else
			Eternus.CommandService:NKAddLocalText("Invalid volume entered as second parameter: " .. args[2] .. "\n")
		end
	end
	
	if args[1] then
		-- Its either a 3d sound, an ambient sound, or doesn't exist.
		local sound = Eternus.SoundSystem:NKGet3DSound(args[1])
		if sound then	-- 3D sound
			sound:NKSetVolume(volume)
			sound:NKPlay3DGlobal(false)
			Eternus.CommandService:NKAddLocalText("Playing 3D sound: " .. args[1] .. "\n")
		else --Ambient sound or not a sound at all!
			sound = Eternus.SoundSystem:NKGetAmbientSound(args[1])
			if sound then -- Ambient sound.
				sound:NKSetVolume(volume)
				sound:NKPlayAmbient(false)
				Eternus.CommandService:NKAddLocalText("Playing ambient sound: " .. args[1] .. 
				"\n")
			else
				Eternus.CommandService:NKAddLocalText("Could not find sound: " .. args[1] .. "\n")
			end
		end
	else
		Eternus.CommandService:NKAddLocalText("Enter a sound name optionally followed by a volume level (on a scale of 0 to 1) as parameters to play that sound.\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for enabling/disabling sound.
function TUGGameMode:ChatCommandSound( userInput, args )
	if args[1] then
		local lowString = string.lower(args[1])
		Eternus.CommandService:NKAddLocalText("\n Comparing " .. lowString .. "\n")
		if lowString == "enable" then
			Eternus.GameConfig:NKSetBoolConfig("disableSound", false)
			Eternus.CommandService:NKAddLocalText("Sound enabled.\nNOTE: Changing this setting will require a game restart to take effect.\n")
		elseif lowString == "disable" then
			Eternus.GameConfig:NKSetBoolConfig("disableSound", true)
			Eternus.CommandService:NKAddLocalText("Sound disabled.\nNOTE: Changing this setting will require a game restart to take effect.\n")
		else
			Eternus.CommandService:NKAddLocalText("Invalid parameter: " .. args[1] .. "\nPossible parameters: enable, disable\n")
		end
	else
		local isDisabled = Eternus.GameConfig:NKGetBoolConfig("disableSound")
		local disabledText = ""
		if isDisabled then
			disabledText = "Sound is currently disabled.\n"
		else
			disabledText = "Sound is currently enabled.\n"
		end
		Eternus.CommandService:NKAddLocalText(disabledText .. "Possible parameters: enable, disable\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for setting/getting the object cull distance
function TUGGameMode:ChatCommandObjectDistance( userInput, args )
	if args[1] then
		local newDist = tonumber(args[1])
		if newDist then
			-- Clamp distance from 3 to 30
			if newDist < 3 then
				newDist = 3
			elseif newDist > 30 then
				newDist = 30
			end
			Eternus.GameConfig:NKSetIntConfig("objectDistance", newDist)
			Eternus.CommandService:NKAddLocalText("Object distance set to: " .. args[1] .. "\n")
		else
			Eternus.CommandService:NKAddLocalText("Invalid object distance value: " .. args[1] .. "\n")
		end
	else
		local curGamma = Eternus.GameConfig:NKGetIntConfig("objectDistance")
		Eternus.CommandService:NKAddLocalText("Current object distance: " .. tostring(curDist) .. "\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for setting/getting gamma correction settings.
function TUGGameMode:ChatCommandGammaCorrection( userInput, args )
	if args[1] then
		local newGamma = tonumber(args[1])
		if newGamma then
			Eternus.GameConfig:NKSetFloatConfig("gammaCorrection", newGamma)
			Eternus.CommandService:NKAddLocalText("Gamma correction set to: " .. args[1] .. "\n")
		else
			Eternus.CommandService:NKAddLocalText("Invalid gamma correction value: " .. args[1] .. "\n")
		end
	else
		local curGamma = Eternus.GameConfig:NKGetFloatConfig("gammaCorrection")
		Eternus.CommandService:NKAddLocalText("Current gamma correction: " .. tostring(curGamma) .. "\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for setting/getting ambient volume
function TUGGameMode:ChatCommandAmbientVolume( userInput, args )
	if args[1] then
		-- Set volume.
		local newVol = tonumber(args[1])
		if newVol then
			Eternus.GameConfig:NKSetFloatConfig("ambientSoundVolume", newVol)
			Eternus.SoundSystem:NKUpdateSoundVolume(newVol, 1)
			Eternus.CommandService:NKAddLocalText("Updating ambient sound volume to: " .. args[1] .. "\n")
		else
			Eternus.CommandService:NKAddLocalText(args[1] .. " is not a valid sound level.\n")
		end
	else
		-- Get volume.
		local curVol = Eternus.GameConfig:NKGetFloatConfig("ambientSoundVolume")
		Eternus.CommandService:NKAddLocalText("Current ambient sound volume: " .. tostring(curVol) .. "\n")
	end
end

-------------------------------------------------------------------------------
-- Chat command for setting/getting volume.
function TUGGameMode:ChatCommandVolume( userInput, args )
	if args[1] then
		-- Set volume.
		local newVol = tonumber(args[1])
		if newVol then
			Eternus.GameConfig:NKSetFloatConfig("soundVolume", newVol)
			Eternus.SoundSystem:NKUpdateSoundVolume(newVol, 0)
			Eternus.CommandService:NKAddLocalText("Updating 3D sound volume to: " .. args[1] .. "\n")
		else
			Eternus.CommandService:NKAddLocalText(args[1] .. " is not a valid sound level.\n")
		end
	else
		-- Get volume.
		local curVol = Eternus.GameConfig:NKGetFloatConfig("soundVolume")
		Eternus.CommandService:NKAddLocalText("Current 3D sound volume: " .. tostring(curVol) .. "\n")
	end
end


-------------------------------------------------------------------------------
-- Chat command for setting/getting the time.  
function TUGGameMode:ChatCommandTime( userInput, args )
	local uiContainer = self.state:NKGetUIContainer()
	local miscUI = uiContainer:NKGetMiscellaneousUI()
	
	
	if args[1] then
		local newTime = tonumber(args[1])
		if newTime then
			-- We have time, set it.
			Eternus.World:NKSetMilitaryTime(tonumber(args[1]))
			
			Eternus.CommandService:NKSendNetworkText("Setting time to: " .. tostring(args[1]) .. "\n")
			-- UIContainer isn't functioning.
			--miscUI:NKChatWindow_AddText("Setting time to: " .. tostring(args[1]))
		else
			Eternus.CommandService:NKAddLocalText("Invalid time: " .. tostring(args[1]) .. "\n")
		end
	else
		-- Print time.
		local theTime = Eternus.World:NKGetMilitaryTime()
		Eternus.CommandService:NKAddLocalText("The time is: " .. tostring(theTime) .. "\n")
		
		--miscUI:NKChatWindow_AddText("The time is: " .. tostring(theTime))
	end
	
	
end

-------------------------------------------------------------------------------
function TUGGameMode:ChatCommandTimeScale(userInput, args)
	
	if args[1] then
		local newScale = tonumber(args[1])
		if newScale then
			Eternus.World:NKSetTimeScale(newScale)
			Eternus.CommandService:NKAddLocalText("Setting time scale to: " .. args[1] .. "\n")
		else
			Eternus.CommandService:NKAddLocalText("Invalid time scale: " .. args[1] .. "\n")
		end
	else
		local theScale = Eternus.World:NKGetTimeScale()
		Eternus.CommandService:NKAddLocalText("The current time scale is: " .. tostring(theScale) .. "\n")
	end
end

-------------------------------------------------------------------------------
function TUGGameMode:ChatCommandViewDistance(userInput, args)
	if args[1] then
		local lowerArgs = string.lower(args[1])
		local newDist = 0
		if lowerArgs == "tiny" then
			newDist = Eternus.ViewDistance.Tiny
		elseif lowerArgs == "small" then
			newDist = Eternus.ViewDistance.Small
		elseif lowerArgs == "normal" then
			newDist = Eternus.ViewDistance.Normal
		elseif lowerArgs == "far" then
			newDist = Eternus.ViewDistance.Far
		else
			local argsNum = tonumber(args[1])
			if argsNum then
				newDist = argsNum
			else
				Eternus.CommandService:NKAddLocalText("Invalid view distance: " .. args[1] .. "\n")
				return
			end
		end
		
		--newDist should be set by now, make sure its not 0 just to be safe.
		if newDist == 0 then
			Eternus.CommandService:NKAddLocalText("Attempting to set view distance to 0.  This should never happen.")
			return
		end
		
		Eternus.GameConfig:NKSetIntConfig("viewDistance", newDist)
		Eternus.World:NKSetViewDistance(newDist)
		EternusEngine.Debugging.GenerationDistance = newDist
		
	else
		local curViewDistance = Eternus.World:NKGetViewDistance()
		local viewDistString = tostring(curViewDistance)
		
		if curViewDistance == Eternus.ViewDistance.Tiny then
			viewDistString = "Tiny"
		elseif curViewDistance == Eternus.ViewDistance.Small then
			viewDistString = "Small"
		elseif curViewDistance == Eternus.ViewDistance.Normal then
			viewDistString = "Normal"
		elseif curViewDistance == Eternus.ViewDistance.Far then
			viewDistString = "Far"
		end
		
		Eternus.CommandService:NKAddLocalText("Current view distance: " .. viewDistString .. "\n")
	end
end

-------------------------------------------------------------------------------
function TUGGameMode:ChatCommandMaxViewDistance(userInput, args)
	if args[1] then
		local lowerArgs = string.lower(args[1])
		local newDist = 0
		if lowerArgs == "tiny" then
			newDist = Eternus.ViewDistance.Tiny
		elseif lowerArgs == "small" then
			newDist = Eternus.ViewDistance.Small
		elseif lowerArgs == "normal" then
			newDist = Eternus.ViewDistance.Normal
		elseif lowerArgs == "far" then
			newDist = Eternus.ViewDistance.Far
		else
			local argsNum = tonumber(args[1])
			if argsNum then
				newDist = argsNum
			else
				Eternus.CommandService:NKAddLocalText("Invalid view distance: " .. args[1] .. "\n")
				return
			end
		end
		
		--newDist should be set by now, make sure its not 0 just to be safe.
		if newDist == 0 then
			Eternus.CommandService:NKAddLocalText("Attempting to set max view distance to 0.  This should never happen.")
			return
		end
		
		Eternus.World:NKSetMaxViewDistance(newDist)
		
	else
		local curViewDistance = Eternus.World:NKGetMaxViewDistance()
		local viewDistString = tostring(curViewDistance)
		
		if curViewDistance == Eternus.ViewDistance.Tiny then
			viewDistString = "Tiny"
		elseif curViewDistance == Eternus.ViewDistance.Small then
			viewDistString = "Small"
		elseif curViewDistance == Eternus.ViewDistance.Normal then
			viewDistString = "Normal"
		elseif curViewDistance == Eternus.ViewDistance.Far then
			viewDistString = "Far"
		end
		
		Eternus.CommandService:NKAddLocalText("Current max view distance: " .. viewDistString .. "\n")
	end
end

-------------------------------------------------------------------------------
function TUGGameMode:ChatCommandSpawn(userInput, args)
	if args[1] then --Have a name.
		local objName = args[1]
		local objCount = 1
		if args[2] then
			objCount = tonumber(args[2])
			if not objCount then
				Eternus.CommandService:NKAddLocalText("Attempting to spawn object " .. objName .. " with invalid count: " .. args[2] .. "\n")
				return
			end
		end
		
		--Obj count was valid or wasn't there, have a name.
		if objCount > 0 then
			local spawnLocation = self.m_activeCamera:NKGetLocation() + (self.m_activeCamera:ForwardVector():mul_scalar(1.0))

			-- Forward the command to player
			self.player:SpawnCommand(objName, objCount, spawnLocation)

			Eternus.CommandService:NKAddLocalText("Attempting to spawn " .. tostring(objCount) .. " of object " .. objName .. "\n")
			--NKPrint("---- Location: " .. spawnLocation:NKToString() .. "\n")
		end
	end
end

function TUGGameMode:ChatCommandTakeDamage(userInput, args)
	if args[1] then --have dmg amount
		local damage = tonumber(args[1])

		if damage then
			self.player:RaiseServerEvent("ServerEvent_TakeDamage", { damage = damage})
		end
	end
end


-------------------------------------------------------------------------------
-- Registers a lua-based slash command for the game.
-- DEPRECATED: Use Eternus.CommandService:NKRegisterChatCommand
-- instead.
function TUGGameMode:RegisterSlashCommand(commandName, tableToCallFunction, functionToCall)
	Eternus.CommandService:NKRegisterChatCommand(string.lower(commandName), "ExecuteSlashCommand")
	local finalString = "/" .. string.lower(commandName)
	self.m_slashCommands[finalString] = {["tab"] = tableToCallFunction, ["func"] = functionToCall}
	NKPrint("LUA Register Slash Command: " .. commandName .. "\n")
end

-------------------------------------------------------------------------------
-- Attempts to execute a lua-based slash command previously registered.  This is attempted
-- to be called on the game mode script itself.
-- DEPRECATED: Use Eternus.CommandService to register slash commands
-- instead.
function TUGGameMode:ExecuteSlashCommand(userInput, args)
	local commandEnd = string.find(userInput, ' ')
	local finalString = userInput
	if (commandEnd) then
		finalString = string.sub(finalString, commandEnd)
	end
	finalString = string.lower(finalString)
	if self.m_slashCommands[finalString] == nil then
		-- Unknown command
		return false
	end
	
	NKPrint("LUA Execute Slash Command Called: " .. finalString .. "\n")
	command = self.m_slashCommands[finalString]
	local retVal = command.tab[command.func](command.tab, args)
	return retVal
end

-------------------------------------------------------------------------------
function TUGGameMode:GetPlayerInstance()
	return self.player
end

-------------------------------------------------------------------------------
function TUGGameMode:ShowPlayers(down)

	if not down then
		-- Turn off the players window
		self.m_gameModeUI.m_playersWindow:setVisible(false)
		self.m_gameModeUI.m_crosshair:setVisible(true)
		return
	end

	-- Turn on the players Window
	if not self.m_gameModeUI.m_playersWindow:isVisible() then
		self.m_gameModeUI.m_playersWindow:setVisible(true)
		self.m_gameModeUI.m_crosshair:setVisible(false)
	end
end

-------------------------------------------------------------------------------
function TUGGameMode:ToggleUI(down)

	if not down then
		return
	end

	-- Hide all UI when toggled
	-- Gets the current state of the mouse so it can restore it when you show the UI again
	if EternusEngine.UI.Layers.Gameplay:isVisible() then
		EternusEngine.UI.Layers.Gameplay:hide()
		NKPrint("Checking IsMouseHidden : " .. tostring(Eternus.InputSystem:NKIsMouseHidden()) .. "\n")
		if Eternus.InputSystem:NKIsMouseHidden() then
			Eternus.InputSystem:NKHideMouse()
			self.m_restoreMouse = false
		else
			self.m_restoreMouse = true
		end
	else
		EternusEngine.UI.Layers.Gameplay:show()
		if self.m_restoreMouse then
			Eternus.InputSystem:NKShowMouse()
		end
	end
end

-------------------------------------------------------------------------------
function TUGGameMode:OnTestPlacement(down)
	-- Base state does nothing!
end

-------------------------------------------------------------------------------
-- Ctr+3: Switch between First and Third person camera.
function TUGGameMode:ToggleCameraMode(down)
	-- Wait for keyup
	if down then 
		return
	end
	
	if self.player:HasDied() then
		return
	end
	
	-- Swap the m_activeCamera
	if self.m_activeCamera ~= self.m_fpcamera then
		self.m_activeCamera = self.m_fpcamera
		self.player:SetCameraMode(LocalPlayer.ECameraMode.First)
	else
		self.m_activeCamera = self.m_tpcamera
		self.player:SetCameraMode(LocalPlayer.ECameraMode.Third)
	end
	
	-- Inform the backing TUGGameMode
	self.state:NKSetActiveCamera(self.m_activeCamera)
end

-------------------------------------------------------------------------------
function TUGGameMode:SyncCameraModeToPlayer()
	local camMode = self.player.m_camMode
	
	if camMode == LocalPlayer.ECameraMode.First then
		self.m_activeCamera = self.m_fpcamera
	elseif camMode == LocalPlayer.ECameraMode.Third then
		self.m_activeCamera = self.m_tpcamera
	end
	self.state:NKSetActiveCamera(self.m_activeCamera)
end

-------------------------------------------------------------------------------
function TUGGameMode:Enter()	
	self.state:NKSetActiveCamera(self.m_activeCamera)
	self.m_stateActive = true
	CL:EnterTUGMods()
end

-------------------------------------------------------------------------------
function TUGGameMode:Leave()
	self.m_stateActive = false
	CL:LeaveTUGMods()
end

-------------------------------------------------------------------------------
function TUGGameMode:IsStateActive()
	return self.m_stateActive
end

-------------------------------------------------------------------------------
function TUGGameMode:SetupUI()
	self.m_gameModeUI = TUGGameModeUIView.new("TUGGameModeLayout.layout")
	self.m_gameModeUI:RegisterScoreboard(gScoreboard)
	-- Add the new player to the scoreboard

	self.player.m_targetAcquiredSignal:Add(function(hitObj)

		if hitObj and hitObj:NKGetInstance() then
			NKPrint("Target Acquired : " .. hitObj:NKGetName() .. "\n")

			if self.m_gameModeUI.m_targetProgressBar:getProperty("ProgressImage") ~= "TUGGame/HealthBarLitGreen" then
				self.m_gameModeUI.m_targetProgressBar:setProperty("ProgressImage", "TUGGame/HealthBarLitGreen")
			end

			self.m_gameModeUI:FadeAlpha(self.m_gameModeUI.m_targetProgressBar, 0.0, 1.0, 0.5)

			local stackCount = nil

			if hitObj:NKGetInstance().GetMaxStackSize then
				stackCount = hitObj:NKGetInstance():GetMaxStackSize()
			end

			if stackCount and stackCount > 1 then
				self.m_gameModeUI:SetTargetText(hitObj:NKGetInstance():GetDisplayName() .. " x " .. tostring(hitObj:NKGetInstance():GetStackSize()))
			else
				self.m_gameModeUI:SetTargetText(hitObj:NKGetInstance():GetDisplayName())
			end
		end
	end)

	self.player.m_targetLostSignal:Add(function()

		self.m_gameModeUI:FadeAlpha(self.m_gameModeUI.m_targetProgressBar, 1.0, 0.0, 0.5)
	end)

	self.player.m_targetHealthChangedSignal:Add(function(hitObj)

		if hitObj and hitObj:NKGetInstance() then
			-- Safety Check if the object exists
			if hitObj:NKGetInstance().GetMaxHitPoints then
				-- If it has HitPoints
				self.m_gameModeUI:SetTargetProgress(hitObj:NKGetInstance():GetHitPoints()/hitObj:NKGetInstance():GetMaxHitPoints())
			elseif hitObj:NKGetInstance():InstanceOf(Character) then
				-- If it is a Controller (Goat, Cat)
				self.m_gameModeUI:SetTargetProgress(hitObj:NKGetInstance():GetCurrentHealth()/hitObj:NKGetInstance():GetMaxHealth())
			else
				self.m_gameModeUI:SetTargetProgress(0.0)
			end
		end
	end)

	EternusEngine.UI.Layers.Gameplay:show()
end


local frameCount = 0
-------------------------------------------------------------------------------
function TUGGameMode:Process(dt)
	CL:ProcessTUGMods()
	--[[
	if frameCount > 60 then
		local str = tostring(collectgarbage("count"))
		NKPrint("GC Size: " .. str .. "\n")
		frameCount = 0
	end
	frameCount = frameCount + 1
	]]--
end


-------------------------------------------------------------------------------
-- Note that only the x and y are used in mouseDelta.
function TUGGameMode:HandleMouse(mouseDelta)
end

-------------------------------------------------------------------------------
-- Returns the LocalPlayer object.
function TUGGameMode:GetLocalPlayer()
	return self.player
end

-------------------------------------------------------------------------------
-- Helper function to quickly spawn a GameObject by name with a given position and rotation.
function TUGGameMode:SpawnGameObject( name, position, rotation )
	local obj = Eternus.GameObjectSystem:NKCreateGameObject(name, true)
	obj:NKSetShouldRender(true, true)
	obj:NKSetPosition(position, false)
	obj:NKSetOrientation(rotation)
	obj:NKPlaceInWorld(false, false)
end

function TUGGameMode:PushToChatQueue( message )
	return self.state:NKGetUIContainer():NKGetMiscellaneousUI():NKChatWindow_AddText(message)
end

function TUGGameMode:GetLightingController()
	return nil
end