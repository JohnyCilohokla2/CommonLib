CL.println("CommonCore hook initialize")

include("Scripts/Core/Common.lua")
include("Scripts/CL/Hook.lua")

local NKPhysics = include("Scripts/Core/NKPhysics.lua")

if CL_PlacementHook == nil then
	CL_PlacementHook = HookClass.Subclass("CL_PlacementHook")
end

function CL_PlacementHook:initialize()
	self.cl_currentMode = 0
	self.cl_name = "PlacementHook"
	
	self.cl_lastConnection = false
end

function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function CL_PlacementHook:GhostHitObject(object, ghostObj, hitObject, distance, hitLoc, ...)

	if not hitObject or not distance or not hitLoc then
		return
	end
	
	local tracedObj = hitObject:NKGetInstance()
	
	if not ghostObj:InstanceOf(ConnectorInterface) or not tracedObj:InstanceOf(ConnectorInterface) then
		return
	end
	
	-- limit distance!
	if (distance > 6) then
		return
	end
	
	local connections = ghostObj:listConnections(tracedObj, hitLoc)
	--CL.println (#connections)
	if (#connections>0) then
		if (self.cl_currentMode>#connections) then
			self.cl_currentMode = 1;
		elseif (self.cl_currentMode<1) then
			self.cl_currentMode = #connections;
		end
		local connection = connections[self.cl_currentMode]
		
		self.cl_lastConnection = connection

		ghostObj:NKSetPosition(tracedObj:NKGetWorldPosition()+connection.targetPostion, false)
		ghostObj:NKSetOrientation(connection.targetRotation)
		
		return CL.hooks.Abort
	end
end

function CL_PlacementHook:TogglePlacementMode2(object, ...)
	self.cl_currentMode = self.cl_currentMode + 1;
	CL.println("Changed mode to ",self.cl_currentMode)
end

function CL_PlacementHook:PrimaryAction_postPlace(object, instance, ...)
	CL.println ("CL_PlacementHook:PrimaryAction_postPlace")
	
	-- TODO move to OnPlace!
	if (instance~=nil and self.cl_lastConnection~=nil and self.cl_currentMode == 2) then
		if instance:InstanceOf(ConnectorInterface) then
			instance:connect(self.cl_lastConnection.selfConnectorName, self.cl_lastConnection.hitConnectorName, self.cl_lastConnection.hit)
			self.cl_lastConnection.hit:NKGetInstance():connect(self.cl_lastConnection.hitConnectorName, self.cl_lastConnection.selfConnectorName, instance)
			--instance:NKGetPhysics():NKDeactivate()
			return -- end
		end
	end
end

local placementHook = CL_PlacementHook:new("PlacementMode")
--CL:addHook("SurvivalPlacementInput:ProcessObjectGhost",placementHook)
CL:addHook("SurvivalPlacementInput:GhostHitObject",placementHook,"GhostHitObject")
CL:addHook("SurvivalPlacementInput:PrimaryAction_postPlace",placementHook,"PrimaryAction_postPlace")
CL:addHook("SurvivalPlacementInput:TogglePlacementMode2",placementHook,"TogglePlacementMode2")