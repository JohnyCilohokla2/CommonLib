function listConnections(self, hitObject, hitLoc)
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

return listConnections