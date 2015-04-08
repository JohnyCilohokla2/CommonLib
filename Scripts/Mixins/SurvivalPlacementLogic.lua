
local NKPhysics = include("Scripts/Core/NKPhysics.lua")

-------------------------------------------------------------------------------
SurvivalPlacementLogic = EternusEngine.Mixin.Subclass("SurvivalPlacementLogic")

NKRegisterEvent("ServerEvent_Place",
	{
		container = "int",
		index = "int",
		quantity = "int",
		origin = "vec3",
		direction = "vec3",
	}
)

NKRegisterEvent("ServerEvent_PlaceAt",
	{
		container = "int",
		index = "int",
		quantity = "int",
		position = "vec3",
		orientation = "quat",
		tKey 	= "boolean",
	}
)

NKRegisterEvent("ServerEvent_DropInventoryItem",
	{
		container = "int",
		index = "int",
		quantity = "int",
		origin = "vec3",
		direction = "vec3",
	}
)

NKRegisterEvent("ServerEvent_DropItem",
	{
		item = "gameObject",
		origin = "vec3",
		direction = "vec3",
	}
)

function SurvivalPlacementLogic:Constructor(args)
end


--[[=======================================================================]]--

-------------------------------------------------------------------------------
-- Places an object into the world. Directly relies on the state of the
--	camera when this function is called.
--	+ Projects object into world and findes non-interpenatrating position
--	+ >Applies mode specific placement logic<
function SurvivalPlacementLogic:ServerEvent_Place( args )
	if not Eternus.IsServer then return end 

	local dropItem = self:_GetItemFromContainer(args.container, args.index)

	if dropItem then

		local originalPos = dropItem:NKGetPosition()
		local orginalOrin = dropItem:NKGetOrientation()

		local finalOrientation, placeWithPhysics = self:RunModeLogic(dropItem, quat.new(1.0, 0.0, 0.0, 0.0))

		dropItem:NKSetOrientation(finalOrientation)

		local projectedPos = nil
		
		local projectedRaycastHit = self:GetProjectedItemRaycastHit(dropItem, args.origin, args.direction)

		if projectedRaycastHit then
			projectedPos = projectedRaycastHit.queryPosition

			--[[
			if (projectedRaycastHit.normal:dot(vec3(0.0, 1.0, 0.0)) < 0.0) or projectedRaycastHit.gameobject then
				placeWithPhysics = true
			end
			--]]

			local placeDir = projectedPos - self:NKGetPosition()
			local placeDirNrm = vec3(placeDir:x(), 0.0, placeDir:z())
			placeDirNrm = placeDirNrm:normalize()

			if not NKPhysics.ObjectSweepCheck(dropItem, projectedPos, vec3(0.0, -1.0, 0.0), 0.05, {self}) and  
				not NKPhysics.ObjectSweepCheck(dropItem, projectedPos, placeDirNrm, 0.05, {self}) then
				placeWithPhysics = true
			end
		else
			projectedPos = NKPhysics.RayCastCollect(args.origin, args.direction, self:GetMaxReachDistance(), {self.object})
			if projectedPos then
				projectedPos = projectedPos.contact
			else
				projectedPos = args.origin + (args.direction * vec3.new(self:GetMaxReachDistance(), self:GetMaxReachDistance(), self:GetMaxReachDistance()))
			end
		end

		dropItem:NKSetPosition(projectedPos)

		--[[
		-- Bail if the placement would overlap the player
		if NKPhysics.ObjectsOverlap(self, dropItem) then

			-- Reset to old state
			dropItem:NKSetOrientation(orginalOrin)
			dropItem:NKSetPosition(originalPos)

			return
		end
		--]]

		local finalDropItem = self:_RemoveItemFromContainer(args.container, args.index, args.quantity)

		finalDropItem:NKSetPosition(projectedPos)
		finalDropItem:NKSetOrientation(finalOrientation)
			
		finalDropItem:NKSetShouldRender(true, true)
		finalDropItem:NKPlaceInWorld(true, false)


		if not placeWithPhysics and projectedRaycastHit then
			finalDropItem:NKGetPhysics():NKDeactivate()
		else 
			finalDropItem:NKGetPhysics():NKActivate()
		end
		
		local objInst = finalDropItem:NKGetInstance()
		if objInst.OnPlace then
			objInst:OnPlace()
		end 

		if self.OnPlace then 
			self:OnPlace()
				--place it animation
				--self.player:Place() 
		end
		-- Finalize the placement
		--self:FinalizePlace(dropItem, projectedPos, finalOrientation, projectedResult)

		--self:FinalizePlaceAt(dropItem, args.position, args.orientation)
	end

	--local oldObj = self:GetItemAt(container, index)
	--if oldObj then
	--	NKPrint("There is still an object at that index.\n")
	--else
	--	NKPrint("That slot is now nil.\n")
	--end
end

-------------------------------------------------------------------------------
-- Places an object into the world. Takes the state that the object should have
--	and must be verified that it is not too far from the player. Relies on the
--	server to verify placement state.
--	+ Directly sets the state, does not check for inpterpenetration.
--	+ >Does NOT apply mode specific placement logic<
function SurvivalPlacementLogic:ServerEvent_PlaceAt( args )
	if not Eternus.IsServer then return end 

	-- the the item from inventory
	local droppedObj = self:GetItemAt(args.container, args.index)
	-- make sure it's valid
	
	local forceDisablePhysics = false
	
	if droppedObj and droppedObj.m_item then
		if (not args.tKey or (not droppedObj.m_item:NKGetPlaceable() or droppedObj.m_item:NKGetPlaceable():NKIsPlacedWithPhysics()))then
			local ignoreList = {}
			if (droppedObj.m_item:NKGetInstance():InstanceOf(ConnectorInterface)) then
				local gameobjects = Eternus.GameObjectSystem:NKGetGameObjectsInRadius(args.position, 10, "all", false);
				for objectID, objectData in pairs(gameobjects) do
					if (objectData:NKGetInstance():InstanceOf(ConnectorInterface)) then
						if (droppedObj.m_item:NKGetInstance():canReconnect(args.orientation, args.position, objectData:NKGetInstance())) then
							table.insert(ignoreList, objectData:NKGetInstance().object);
							forceDisablePhysics = true
							CL.println("Can reconnect!")
							--CL.println(objectData:NKGetInstance())
							--CL.println(objectData:NKGetInstance().object)
						else
							CL.println("Can't reconnect!")
						end
					end
				end
			end
			if ((not next(ignoreList) == nil) or not args.tKey or (not droppedObj.m_item:NKGetPlaceable() or droppedObj.m_item:NKGetPlaceable():NKIsPlacedWithPhysics()))then
				-- make sure it is rotated the right way
				droppedObj.m_item:NKSetOrientation(args.orientation)
				-- check to make sure it has space
				local traceResult = NKPhysics.ObjectSweepCollect(droppedObj.m_item, args.position, vec3.new(0.0, 1.0, 0.0), 0.0001, ignoreList)
				-- if the sweep test returned anything, there is something in the way
				if traceResult then
					-- try to check a bit above, to make sure it isn't aligned with the surface
					local traceResult = NKPhysics.ObjectSweepCollect(droppedObj.m_item, args.position+vec3.new(0.0, 0.1, 0.0), vec3.new(0.0, -1.0, 0.0), 0.0001, ignoreList)
					-- if the sweep test returned anything, there is something in the way
					if traceResult then
						-- play sound to let the user know the object was blocked by something and cancel the placement
						self:RaiseClientEvent("ClientEvent_FailedPlace", {})
						return
					end
				end
			end
		end
	else
		return -- there is no item to place
	end
	
	local dropItem = self:_RemoveItemFromContainer(args.container, args.index, args.quantity)

	if dropItem then 
		-- Finalize the placement
		self:FinalizePlaceAt(dropItem, args.position, args.orientation, forceDisablePhysics)
		
		local objInst = dropItem:NKGetInstance()
		if objInst.OnPlace then
			objInst:OnPlace()
		end 

		if self.OnPlace then 
			self:OnPlace()
				--place it animation
				--self.player:Place() 
		end
	end
end


function SurvivalPlacementLogic:CheckResult( result )

	if type(result) == "table" then
		if table.getn(result) == 0 then
			NKPrint("Normal: " .. result.normal:NKToString() .. "\n")
			NKPrint("Contact: " .. result.contact:NKToString() .. "\n")
			NKPrint("QPosition: " .. result.queryPosition:NKToString() .. "\n")
			NKPrint("Distance: " .. result.distance .. "\n")
			NKPrint("MatID: " .. result.matID .. "\n")
			if result.body then
				NKPrint("Body: " .. tostring(result.body) .. "\n")
			end
			if result.gameobject then
				NKPrint("GameObject: " .. tostring(result.gameobject) .. "\n")
			end
			NKPrint("InternalType: " .. result.internalType .. "\n")
		else
			NKPrint("Hits: " .. table.getn(result) .. "\n")
			for i = 1, table.getn(result) do
				NKPrint("Hit: " .. i .. "\n")
				NKPrint("----Normal: " .. result[i].normal:NKToString() .. "\n")
				NKPrint("----Contact: " .. result[i].contact:NKToString() .. "\n")
				NKPrint("----QPosition: " .. result[i].queryPosition:NKToString() .. "\n")
				NKPrint("----Distance: " .. result[i].distance .. "\n")
				NKPrint("----MatID: " .. result[i].matID .. "\n")
				if result[i].body then
					NKPrint("----GameObject: " .. tostring(result[i].gameobject) .. "\n")
				end
				NKPrint("----Body: " .. tostring(result[i].body) .. "\n")
				if result[i].gameobject then
					NKPrint("----GameObject: " .. tostring(result[i].gameobject) .. "\n")
				end
				NKPrint("----InternalType: " .. result[i].internalType .. "\n")
			end
		end
	elseif type(result) == "boolean" then
		if result then
			NKPrint("Did hit something.\n")
		else
			NKPrint("Did NOT hit something.\n")
		end
	else
		NKPrint("Did not understand the return value...\n++++++++++++++++++++++++++++++\n")
		NKPrint("[Table]: " .. EternusEngine.Debugging.Inspect(result) .. "\n++++++++++++++++++++++++++++++\n")
	end
	
end

-------------------------------------------------------------------------------
-- Places an object into the world. Takes the entire stack in the hand and
--	projects it into the world for placement.
--	+ Drops entire stack
--	+ >Does NOT apply mode specific placement logic<
function SurvivalPlacementLogic:ServerEvent_DropInventoryItem( args )
	if not Eternus.IsServer then
		return
	end 

	local dropItem = self:_RemoveItemFromContainer(args.container, args.index, args.quantity)
	if dropItem then
		self:_PlaceItemInWorld(dropItem, args.origin, args.direction)
	end
end

-------------------------------------------------------------------------------
-- Places an object into the world.
-- Does NOT apply mode specific placement logic<
function SurvivalPlacementLogic:ServerEvent_DropItem( args )
	if not Eternus.IsServer then
		return
	end 

	self:_PlaceItemInWorld(args.item, args.origin, args.direction)
end

--[[=======================================================================]]--

-------------------------------------------------------------------------------
-- Private

-------------------------------------------------------------------------------
--function SurvivalPlacementLogic:RunModeLogic(object, position, orientation, placementContact)
function SurvivalPlacementLogic:RunModeLogic(object, orientation)

	local dynamicPhysics = true

	-- Ghost placement is a special type of placement that overrides any
	--	baked placement logic via Placeable Schematic fields. Thus, if
	--	it's active; skip this baked mode specific logic.
	local placeableComponent = object:NKGetPlaceable()

	-- Placeable objects can have special logic attached to them.
	if placeableComponent then

		local rotOffset = placeableComponent:NKGetRotOffset()
		local q = quat.new(0.0,0.0,1.0,0.0)

		-- If the rotation offset is NOT an identity orientation,
		--	build a new orientation that representes the offset rotation.
		if rotOffset ~= quat.new(1.0,0.0,0.0,0.0) then
	 		GLM.Rotate(q, rotOffset:w(), vec3.new(rotOffset:x(), rotOffset:y(), rotOffset:z()))
	 		orientation = q
		end

		-- If the object should align with the forward vector of the camera
		--	calculate the appropriate quaternion.
		if placeableComponent:NKShouldFaceCamera() then 
			-- <KLUDGE> Until we can find a better way to obscure, hide or bake this information
			--	into a player we will need to grab their controller's (camera) theta directly from the
			--	WorldPlayer object.
			local theta = self:NKGetWorldPlayer():NKGetTheta()
			-- </KLUDGE>

			GLM.Rotate(q, math.deg(theta), NKMath.Up)
			orientation = q
		end

		dynamicPhysics = placeableComponent:NKIsPlacedWithPhysics()
	end
	return orientation, dynamicPhysics
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:FinalizePlace(object, position, orientation, placementContact)
	if not Eternus.IsServer then return end

	local finalPosition, finalOrientation, dynamicPhysics = self:RunModeLogic(object, position, orientation, placementContact)

	object:NKSetPosition(finalPosition)
	object:NKSetOrientation(finalOrientation)
	object:NKSetShouldRender(true, true)
	object:NKPlaceInWorld(true, false)

	if dynamicPhysics then 
		object:NKGetPhysics():NKActivate()
	else 
		object:NKGetPhysics():NKDeactivate()
	end
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:FinalizePlaceAt(object, position, orientation, forceDisablePhysics)
	if not Eternus.IsServer then return end

	object:NKSetPosition(position, true)
	object:NKSetOrientation(orientation)
	object:NKSetShouldRender(true, true)

	if object:NKGetPlaceable() and not object:NKGetPlaceable():NKIsPlacedWithPhysics() then

		local placeDir = position - self:NKGetPosition()
		local placeDirNrm = vec3(placeDir:x(), 0.0, placeDir:z())
		placeDirNrm = placeDirNrm:normalize()

		local hasTouch = false
		if NKPhysics.ObjectSweepCheck(object, position, vec3(0.0, -1.0, 0.0), 0.05, {self}) or 
			NKPhysics.ObjectSweepCheck(object, position, vec3(0.0, 1.0, 0.0), 0.05, {self}) or 
			NKPhysics.ObjectSweepCheck(object, position, placeDirNrm, 0.05, {self}) then
			hasTouch = true
		end

		object:NKPlaceInWorld(true, false)

		if hasTouch or forceDisablePhysics then
			object:NKGetPhysics():NKDeactivate()
		else
			object:NKGetPhysics():NKActivate()
		end
	else
		object:NKPlaceInWorld(true, false)
		object:NKGetPhysics():NKActivate()
	end
end

-------------------------------------------------------------------------------
-- Helper function that removes a given quantity of items from a container
--	handles stacks and drop amounts.
--	Arguments:
--		container - the container name
--		index - the location within the container
--		quantity - amount to drop (0 drops entire stack)
--	Return - Dropped GameObject
function SurvivalPlacementLogic:_RemoveItemFromContainer(container, index, quantity)
	if quantity and quantity == 0 then
		quantity = nil
	end

	local droppedObj = self:GetItemAt(container, index)

	if droppedObj == nil then
		-- We are trying to drop an item from a slot that is empty, return
		return nil
	end

	local initialSize = droppedObj:GetStackSize()
	local remainingSize = self:Drop(container, index, quantity)
	local dropAmount = initialSize - remainingSize

	-- If quantity is nil, we will drop all of the items in that stack
	if remainingSize > 0 then
		-- If there are still some in our inventory after the removal, we need to split the stack
		-- And spawn a new object to hold the dropped amount
		droppedObj = Eternus.GameObjectSystem:NKCreateNetworkedGameObject(droppedObj:GetName(), true, true)

		if dropAmount > 0 then
			droppedObj:NKGetInstance():SetStackSize(dropAmount)
		end
	else
		-- If there were none left drop the gameobject that is in the slot
		droppedObj = droppedObj.m_item
	end

	return droppedObj
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:_GetItemFromContainer(container, index)
	local droppedObj = self:GetItemAt(container, index)

	if droppedObj then
		return droppedObj.m_item
	else
		return nil
	end
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:_PlaceItemInWorld( item, origin, direction)
	local projectedPos = self:GetProjectedItemPosition(item, origin, direction)
	self:FinalizePlaceAt(item, projectedPos, quat.new(1.0, 0.0, 0.0, 0.0))
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:GetProjectedItemRaycastHit( item, origin, direction )
	local maxTether = self:GetMaxReachDistance() * item:NKGetPlaceable():NKGetTetherDistanceModifier()
	local distCheck = NKPhysics.RayCastCollect(origin, direction, maxTether, {self.object})

	if distCheck then 
		maxTether = distCheck.distance
	end

	local startFraction = math.max(0.0, math.min(item:NKGetBounds():NKGetRadius() / maxTether, 0.9))
	local hits = NKPhysics.ObjectSweepCollectAll(item, origin, direction, maxTether + 0.2, {self.object}, startFraction)

	if hits == nil then
		return nil
	end

	if EternusEngine.Debugging.Enabled then
		--NKWarn("Ignoring first %" .. tostring(100 * startFraction) .. " of NKPhysics.ObjectSweepCollectAll")
		--NKWarn("[SurvivalPlacementLogic:GetProjectedItemRaycastHitTest] Hits: " .. table.getn(hits))

		self.m_persistentManifolds = {}
		self.m_persistentRays = {}

		table.insert(self.m_persistentRays, {origin = origin, direction = direction, distance = maxTether})
	end

	for key, hit in pairs(hits) do
		item:NKSetPosition(hit.queryPosition)

		if EternusEngine.Debugging.Enabled then
			table.insert(self.m_persistentManifolds, hit)
		end
	end

	return hits[1]
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:GetProjectedItemPosition( item, origin, direction )
	local maxReach = self:GetMaxReachDistance()
	local maxTether = maxReach * item:NKGetPlaceable():NKGetTetherDistanceModifier()
	
	local result = NKPhysics.ObjectSweepCollect(item, origin, direction, maxTether, {self.object})

	if result then
		return result.queryPosition
	else
		return origin + (direction * vec3.new(maxReach, maxReach, maxReach))
	end
end

return SurvivalPlacementLogic