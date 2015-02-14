function isWithinBB(vector, boundingBox)
	if(vector:x() > boundingBox.minX and vector:x() < boundingBox.maxX)
	and(vector:y() > boundingBox.minY and vector:y() < boundingBox.maxY)
	and(vector:z() > boundingBox.minZ and vector:z() < boundingBox.maxZ)
	then
		return true
	end
	return false;
end

function getBB(parentPosition, rotation, boundingBox, out)
	local sorted = true;
	if(out == nil) then
		out = { };
		sorted = false;
	end

	local invQuat = rotation:NKGetInverse();

	local centerX =(boundingBox.maxX + boundingBox.minX) / 2
	local centerY =(boundingBox.maxY + boundingBox.minY) / 2
	local centerZ =(boundingBox.maxZ + boundingBox.minZ) / 2

	local extX =(boundingBox.maxX - boundingBox.minX) / 2
	local extY =(boundingBox.maxY - boundingBox.minY) / 2
	local extZ =(boundingBox.maxZ - boundingBox.minZ) / 2

	local localPosition = vec3.new(centerX, centerY, centerZ)

	local radius = math.sqrt(extX * extX + extY * extY + extZ * extZ)

	local gameobjects = Eternus.GameObjectSystem:NKGetGameObjectsInRadius(parentPosition +(localPosition:mul_quat(rotation)), radius, "all", false);
	for objectID, objectData in pairs(gameobjects) do
		local objectPosition = objectData:NKGetWorldPosition()

		local relativePosition =(objectPosition - parentPosition):mul_quat(invQuat);
		if(relativePosition:x() > boundingBox.minX and relativePosition:x() < boundingBox.maxX)
		and(relativePosition:y() > boundingBox.minY and relativePosition:y() < boundingBox.maxY)
		and(relativePosition:z() > boundingBox.minZ and relativePosition:z() < boundingBox.maxZ)
		then
			if (sorted==true) then 
				if(out [ objectData:NKGetName() ] ~= nil) then
					table.insert(out [ objectData:NKGetName() ], objectData);
				end
			else
				table.insert(out, objectData);
			end
		end

	end
	return out;
end

function getQBB(parentPosition, localPosition, rotation, localRotation, sides, out)
	if (out==nil) then
		out = {};
		out["Copper Ore"] = {};
		out["Tin Ore"] = {};
	end
	
	local invQuat = rotation:NKGetInverse();
	
	--local centerX = (boundingBox.maxX+boundingBox.minX)/2
	--local centerY = (boundingBox.maxY+boundingBox.minY)/2
	--local centerZ = (boundingBox.maxZ+boundingBox.minZ)/2
	--local diffX = boundingBox.maxX-boundingBox.minX
	--local diffY = boundingBox.maxY-boundingBox.minY
	--local diffZ = boundingBox.maxZ-boundingBox.minZ
	--local localPosition = vec3.new(centerX,centerY,centerZ)
	local radius = math.sqrt(sides.distX*sides.distX + sides.distY*sides.distY + sides.distZ*sides.distZ)
	--print (radius)

	local gameobjects = Eternus.GameObjectSystem:NKGetGameObjectsInRadius(parentPosition+(localPosition:mul_quat(rotation)), radius, "all", false);
		for objectID,objectData in pairs(gameobjects) do
			local objectPosition = objectData:NKGetWorldPosition()
		
			local relativePosition = (((objectPosition-parentPosition):mul_quat(invQuat))-localPosition):mul_quat(localRotation);
			--print(relativePosition:x(),relativePosition:y(),relativePosition:z());
			
			if (relativePosition:x()>-sides.distX and relativePosition:x()<sides.distX) 
				and (relativePosition:y()>-sides.distY and relativePosition:y()<sides.distY) 
				and (relativePosition:z()>-sides.distZ and relativePosition:z()<sides.distZ)
			then
				if (out[objectData:NKGetName()]~=nil) then
					table.insert(out[objectData:NKGetName()],objectData);
				else
					out[objectData:NKGetName()] = {};
					table.insert(out[objectData:NKGetName()],objectData);
				end
			else
				--print("out",objectData:NKGetName())
			end
			
		end
	return out;
end