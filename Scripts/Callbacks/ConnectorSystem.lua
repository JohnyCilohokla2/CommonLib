CL.println("CommonCore hook initialize")

local NKPhysics = include("Scripts/Core/NKPhysics.lua")

local ConnectorCallback = CallbackClass.Subclass("ConnectorCallback")

function ConnectorCallback:Constructor()
	self.cl_currentMode = 0
	self.cl_name = "PlacementHook"
	
	self.cl_lastConnection = false
end

function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

-------------------------------------------------------------------------------
function ConnectorCallback:RaycastGhostObject( cameraPos, fwdVec, maxDistance, ignoreTab )
	local queryMask = BitFlags32()
	queryMask:NKSetBit(EternusEngine.Physics.Layers.DEFAULT)
	queryMask:NKSetBit(EternusEngine.Physics.Layers.TERRAIN)
	return NKPhysics.RayCastCollectAll(cameraPos, fwdVec, maxDistance * 1.1, ignoreTab, queryMask)
end

-------------------------------------------------------------------------------
function ConnectorCallback:ProcessGhostObjectOverride(object, ret, ghostObj, hitObject, distance, hitLoc, ...)
	local ghostObj = object.m_ghostObject
	if not ghostObj then
		return
	end
	
	-- Find the closest max distance
	local maxDistance = 8
	
	local camera = EternusEngine.GameMode.m_activeCamera
	local rayResult = self:RaycastGhostObject(camera:NKGetLocation(), camera:ForwardVector(), maxDistance, {object})
	
	local hitObject = nil
	local hitLoc = nil
	if rayResult then
		for key, hit in pairs(rayResult) do
			if hit.distance < maxDistance then
				maxDistance = hit.distance
				hitLoc = hit.point
				hitObject = hit.gameobject
			end
		end
	end

	if not hitObject or not hitLoc then
		return
	end
	
	if not ghostObj:InstanceOf(ConnectorInterface) or not hitObject:InstanceOf(ConnectorInterface) then
		return
	end
	
	local connections = ghostObj:listConnections(hitObject, hitLoc)
	--CL.println (#connections)
	if (#connections>0) then
		if (self.cl_currentMode>#connections) then
			self.cl_currentMode = 1;
		elseif (self.cl_currentMode<1) then
			self.cl_currentMode = #connections;
		end
		local connection = connections[self.cl_currentMode]
		
		self.cl_lastConnection = connection

		ghostObj:NKSetPosition(hitObject:NKGetWorldPosition()+connection.targetPostion, false)
		ghostObj:NKSetOrientation(connection.targetRotation)
		
		ret.status = EternusEngine.ECallbackAction.Abort
		return 
	end
end

function ConnectorCallback:TogglePlacementMode(down)
	if not down then
		return
	end
	self.cl_currentMode = self.cl_currentMode + 1;
	CL.println("Changed mode to ",self.cl_currentMode)
end

function ConnectorCallback:ServerEvent_PlaceAt(object, ret, args, droppedObj, ignoreList, ...)
	local ignoreList = {}
	if (droppedObj:InstanceOf(ConnectorInterface)) then
		local gameobjects = Eternus.GameObjectSystem:NKGetGameObjectsInRadius(args.position, 10, "all", false);
		for objectID, objectData in pairs(gameobjects) do
			if (objectData:InstanceOf(ConnectorInterface)) then
				if (droppedObj:canReconnect(args.orientation, args.position, objectData)) then
					table.insert(ignoreList, objectData);
					ret.forceDisablePhysics = true
					CL.println("Can reconnect!")
				else
					CL.println("Can't reconnect!")
				end
			end
		end
	end
end
return ConnectorCallback