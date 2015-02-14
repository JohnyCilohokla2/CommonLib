include("Scripts/Core/Common.lua")

-------------------------------------------------------------------------------
if ConnectorInterface == nil then
	ConnectorInterface = EternusEngine.Mixin.Subclass("ConnectorInterface")
	ConnectorInterface.CLRelations = {
	itemIn = "itemOut",
	itemOut = "itemIn",
	itemLogicalIn = "itemLogicalOut",
	itemLogicalOut = "itemLogicalIn",
	itemDropIn = "itemDropOut",
	itemDropOut = "itemDropIn",
	itemDropLIn = "itemDropROut",
	itemDropLOut = "itemDropRIn",
	itemDropRIn = "itemDropLOut",
	itemDropROut = "itemDropLIn"
	}
end

--[[
TODO:
position, rotation, types[list], 


]]--

function ConnectorInterface.isConnectorCompatible(selfConnectorName, hitConnectorName, selfConnector, hitConnector)
	if (ConnectorInterface.CLRelations[hitConnectorName] == selfConnectorName) then
		return true
	end
	return false
end


function ConnectorInterface:initializeConnector()
	
	
end

function ConnectorInterface:setupConnector()
	self.cl_connections = {}
	if (self.cl_connectorInitialized==false) then
		self:initializeConnector()
	end
	self.cl_connectorInitialized = true
end

function ConnectorInterface:canConnect(connection)
	self:setupConnector()
	--[[
	
	
	]]--
	
	return false
end



function ConnectorInterface:listConnections(hitObject, hitLoc)
	self:setupConnector()
	--[[
		get relative positions
		iterate through in(input/acceptor) -> out (output/emitter)
		iterate through out -> in
		sort by distance to hitLocation
		Notes:
		cache!
	]]--
	local hitRot = hitObject:NKGetWorldOrientation();
	local hitInvRot = hitRot:NKGetInverse();
	local relHit = (hitLoc - hitObject:NKGetWorldPosition()):mul_quat(hitInvRot)
	
	local hitConnectors = {}
	for k,v in pairs(hitObject.CLConnectors) do
		table.insert(hitConnectors,{name = k,connector = v, distance = ((relHit - v.pos):length())})
	end
	
	table.sort( hitConnectors, function( a,b ) return a.distance < b.distance end )
	
	
	local inspect = require "Game.Core.Scripts.Utils.inspect";
	--CL.println(inspect.inspect(hitConnectors));
	if (hitConnectors[1] ~=nil) then
		hitConnector = hitConnectors[1]
		local connectorList = {}
		for hitTypeID,hitTypeName in pairs(hitConnector.connector.types) do
			for selfConnectorID,selfConnector in pairs(self.CLConnectors) do
				for selfTypeID, selfTypeName in pairs(selfConnector.types) do
					if (ConnectorInterface.isConnectorCompatible(selfTypeName, hitTypeName, selfConnector, hitConnector.connector)) then
						--DEBUGGING!
						--self:NKSetPosition(hitObject:NKGetWorldPosition()+(hitConnector.connector.pos:mul_quat(hitRot))-((selfConnector.pos:mul_quat(hitRot):mul_quat(hitConnector.connector.rotation):mul_quat(selfConnector.rotation))), false)
						--self:NKSetOrientation(hitRot*hitConnector.connector.rotation*selfConnector.rotation)
						local selfRotation = selfConnector.rotation; --:rotate(math.rad(180), vec3.new(0.0, 1.0, 0.0))
						local hitRotation = (hitConnector.connector.rotation);
						--hitRotation = quat.new(hitRotation:w(), -hitRotation:x(), -hitRotation:y(), -hitRotation:z())
						
						
						local connectorRotation = hitRot*(hitRotation*selfRotation);
						
						local selfPosition = (selfConnector.pos:mul_quat(connectorRotation));
						
						local connectorPos = (hitConnector.connector.pos:mul_quat(hitRot))						
						
						local tPos = (connectorPos-selfPosition);
						
						
						local tRot = hitRot*((hitRotation*selfConnector.rotation):NKGetInverse());
						table.insert(connectorList, {from = hitTypeName, to = selfTypeName, selfConnector = selfConnector, hitConnector = hitConnector.connector, target = selfConnector, targetPostion = tPos, targetRotation = tRot})
						--return false
					end
				end
			end
		end
		return connectorList
	else
		return {}
	end
end

function ConnectorInterface:debugConnector()
	CL.println("-----------------------------------");
	if (self.cl_connections ~=nil) then
		for connectionID, connectionData in pairs(self.cl_connections) do 
			CL.println(connectionID, connectionData);
		end
	end
	CL.println("***********************************");
	CL.println("Connections: ");
	if (self.CLConnectors ~=nil) then
		for connectionID, connectionData in pairs(self.CLConnectors) do 
			CL.println(connectionID, connectionData);
		end
	end
	CL.println("-----------------------------------");
	local inspect = require "Game.Core.Scripts.Utils.inspect";
	CL.println(inspect.inspect(self));
	CL.println("-----------------------------------");
end