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
		itemDropROut = "itemDropLIn",
		liquidDropOut = "liquidDropIn",
		liquidDropIn = "liquidDropOut"
	}
end

function ConnectorInterface:connectionsUpdate(dt)
	if (self.cl_connectionTick==nil) then
		self.cl_connectionTick = 0
	end
	if (self.cl_connectionTick==0.5) then
		return
	end
	self.cl_connectionTick = self.cl_connectionTick + dt;
	
	if (self.cl_connectionTick>0.5) then
		self.cl_connectionTick = 0.5
		self:initializeConnections()
	end
end

function ConnectorInterface:OnPlace()
	NKPrint("ConnectorInterface:OnPlace()\n")
	self:initializeConnections()
	--self:NKGetPhysics():NKDeactivate()
end

function ConnectorInterface.isConnectorCompatible(selfConnectorName, otherConnectorName, selfConnector, otherConnector)
	if (ConnectorInterface.CLRelations[otherConnectorName] == selfConnectorName) then
		return true
	end
	return false
end

function ConnectorInterface:compareVec3(vector1, vector2, delta)
	local diff = (vector1-vector2):NKLength()
	if (diff<(delta or 0.00001)) then
		return true
	end
	return false
end

function ConnectorInterface:reconnect(other)
	local selfRot = self:NKGetWorldOrientation();
	local otherRot = other:NKGetWorldOrientation();
	
	local selfPos = self:NKGetWorldPosition();
	local otherPos = other:NKGetWorldPosition();
	
	for otherConnectorID,otherConnector in pairs(other.CLConnectors) do
		for otherTypeID,otherTypeName in pairs(otherConnector.types) do
			for selfConnectorID, selfConnector in pairs(self.CLConnectors) do
				for selfTypeID, selfTypeName in pairs(selfConnector.types) do
					if (ConnectorInterface.isConnectorCompatible(selfTypeName, otherTypeName, selfConnector, otherConnector)) then
						local selfConnectionPos = selfPos + selfConnector.pos:mul_quat(selfRot)
						local otherConnectionPos = otherPos + otherConnector.pos:mul_quat(otherRot)
						
						if (CL.compareVec3(selfConnectionPos,otherConnectionPos)) then
							CL.println(other:NKGetName().." reconnecting "..self:NKGetName())
							self:connect(selfConnectorID, otherConnectorID, other)
							other:connect(otherConnectorID, selfConnectorID, self)
							self:NKGetPhysics():NKDeactivate()
							other:NKGetPhysics():NKDeactivate()
						end
						
					end
				end
			end
		end
	end
end

function ConnectorInterface:canReconnect(selfRot, selfPos, other)
	local otherRot = other:NKGetWorldOrientation();
	local otherPos = other:NKGetWorldPosition();
	
	for otherConnectorID,otherConnector in pairs(other.CLConnectors) do
		for otherTypeID,otherTypeName in pairs(otherConnector.types) do
			for selfConnectorID, selfConnector in pairs(self.CLConnectors) do
				for selfTypeID, selfTypeName in pairs(selfConnector.types) do
					if (ConnectorInterface.isConnectorCompatible(selfTypeName, otherTypeName, selfConnector, otherConnector)) then
						local selfConnectionPos = selfPos + selfConnector.pos:mul_quat(selfRot)
						local otherConnectionPos = otherPos + otherConnector.pos:mul_quat(otherRot)
						
						CL.println(other:NKGetName().." trying "..self:NKGetName().." "..selfTypeID)
						if (CL.compareVec3(selfConnectionPos,otherConnectionPos)) then
							CL.println(other:NKGetName().." can connect to "..self:NKGetName())
							return true
						else
							CL.println(other:NKGetName().." can't connect to "..self:NKGetName().." ")
							CL.println(selfConnectionPos:NKToString().." "..otherConnectionPos:NKToString())
							CL.println((selfConnectionPos-otherConnectionPos):NKLength())
						end
					end
				end
			end
		end
	end
	return false
end

function ConnectorInterface:initializeConnector()
		
end

function ConnectorInterface:initializeConnections()
	CL.println(self:NKGetName().." ConnectorInterface:initializeConnections()")	
	Eternus.EventSystem:NKBroadcastEventInRadius("Event_SeekingConnection", self:NKGetPosition(), 10.0, self)	
end

function ConnectorInterface:Event_SeekingConnection(object)
	CL.println(object:NKGetName().." Event_SeekingConnection()"..self:NKGetName())
	self:reconnect(object:NKGetInstance())
end
function ConnectorInterface:setupConnection()
	self:setupConnector()
	if (self.cl_connectorInitialized and not self.cl_connectionsInitialized) then
		self.cl_connections = {}
		self:initializeConnections()
		self.cl_connectionsInitialized = true
	end
end

function ConnectorInterface:setupConnector()
	if (not self.cl_connectorInitialized) then
		self.cl_connections = {}
		self:initializeConnector()
		CL.println("setupConnector()");
	end
	self.cl_connectorInitialized = true
end

function ConnectorInterface:getConnection(slot)
	if (self.cl_connections~=nil and self.cl_connections[slot]~=nil and self.cl_connections[slot].object~=nil) then
		return self.cl_connections[slot]
	end
	return nil
end

function ConnectorInterface:connect(from, to, other)
	self:setupConnector()
	self.cl_connections[from] = {from = from, to = to, object = other}
	CL.println("Connecting "..from.."->"..to);
	--self:debugConnector()
	--other:debugConnector()
end

function ConnectorInterface:disconnect(slot)
	self:setupConnector()
	self.cl_connections[slot] = nil
	CL.println("Disconnecting "..slot);
end

function ConnectorInterface:disconnectAll()
	self:setupConnector()
	for connectionID, connectionData in pairs(self.cl_connections) do 
		ConnectorInterface.disconnect(connectionData.object, connectionData.to)
		CL.println("Disconnecting "..connectionData.from.."(self)");
	end
	self.cl_connections = {}
end


function ConnectorInterface:listConnections(hitObject, hitLoc)
	self:setupConnector() -- just to make sure
	
	local hitRot = hitObject:NKGetWorldOrientation();
	local hitInvRot = hitRot:NKGetInverse();
	local relHit = (hitLoc - hitObject:NKGetWorldPosition()):mul_quat(hitInvRot)
	
	local hitConnectors = {}
	for k,v in pairs(hitObject.CLConnectors) do
		table.insert(hitConnectors,{name = k,connector = v, distance = ((relHit - v.pos):length())})
	end
	
	table.sort( hitConnectors, function( a,b ) return a.distance < b.distance end )
	
	if (hitConnectors[1] ~=nil) then
		hitConnector = hitConnectors[1]
		local connectorList = {}
		for hitTypeID,hitTypeName in pairs(hitConnector.connector.types) do
			for selfConnectorID,selfConnector in pairs(self.CLConnectors) do
				for selfTypeID, selfTypeName in pairs(selfConnector.types) do
					if (ConnectorInterface.isConnectorCompatible(selfTypeName, hitTypeName, selfConnector, hitConnector.connector)) then
					
						local selfRotation = (selfConnector.rotation):NKGetInverse();
						local hitRotation = hitConnector.connector.opposite
						
						local connectorRotation = (selfRotation*hitRotation);
						
						local selfPosition = selfConnector.pos:mul_quat(connectorRotation):mul_quat(hitRot);
						
						local connectorPos = (hitConnector.connector.pos:mul_quat(hitRot))				
						
						local tPos = (connectorPos-selfPosition);
						
						
						local tRot = (connectorRotation)* hitRot;
						table.insert(connectorList, 
							{
							hit = hitObject,
							selfType = selfTypeName, hitType = hitTypeName,
							selfConnectorName = selfConnectorID, hitConnectorName = hitConnector.name,
							selfConnector = selfConnector, hitConnector = hitConnector.connector,
							target = selfConnector,
							targetPostion = tPos, targetRotation = tRot,
							selfName = selfConnectorID, hitName = hitConnector.name
							}
						)
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