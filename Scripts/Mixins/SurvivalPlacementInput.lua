
local NKPhysics = include("Scripts/Core/NKPhysics.lua")

include("Scripts/CL/CL.lua")

-------------------------------------------------------------------------------
SurvivalPlacementInput = EternusEngine.Mixin.Subclass("SurvivalPlacementInput")

-- These need to be defined somewhere else...
--	they are too isolated and forgotten in this file.
local MAX_RAYCAST_DISTANCE = 6.0
-------------------------------------------------------------------------------

NKRegisterEvent("ClientEvent_FailedPlace", 
	{
		
	}
)

-------------------------------------------------------------------------------
function SurvivalPlacementInput:Constructor(args)
	self.m_ghostObject 				= nil
	self.m_ghostPlacementActive 	= false
	self.m_didPlace 				= false
	self.m_zPlacementSensitivity 	= 0.5
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:Spawn()
	Eternus.World:NKGetKeybinds():NKRegisterNamedCommand("Drop Item", self, "DropHandItem", KEY_ONCE)
	Eternus.World:NKGetKeybinds():NKRegisterNamedCommand("Toggle Placement Mode", self, "TogglePlacementMode", KEY_ONCE)
	Eternus.World:NKGetKeybinds():NKRegisterDirectCommand("R", self, "TogglePlacementMode2", KEY_ONCE)
	Eternus.World:NKGetKeybinds():NKRegisterNamedCommand("Toggle Placement Mode3", self, "TogglePlacementMode3", KEY_ONCE)
	--Eternus.InputSystem:NKRegisterInputEvent("Drop Item", self, "DropHandItem", KEY_ONCE)
	--Eternus.InputSystem:NKRegisterInputEvent("Toggle Placement Mode", self, "TogglePlacementMode", KEY_ONCE)
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:TogglePlacementMode2(down)
	if not down or self:IsDead() then
		return
	end

	local hookRet = CL:hook("SurvivalPlacementInput:TogglePlacementMode2",self)
end
-------------------------------------------------------------------------------
function SurvivalPlacementInput:TogglePlacementMode3(down)
	if not down or self:IsDead() then
		return
	end

	local hookRet = CL:hook("SurvivalPlacementInput:TogglePlacementMode3",self)
end

-------------------------------------------------------------------------------
-- Hooks
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function SurvivalPlacementInput:Update(dt)
	self:VerifyState()
	self:UpdateGhostPlacement(dt)

	-- This will try and auto disable placement mode if an item in the hand
	--	is removed for an unknown reason. IE: Server says its not there or
	--	a round trip delivery removes an item that was once a stack.
	if not self.m_equippedItem and self:IsGhostPlacementActive() then
		self:SetPlacementMode(false)
		self:SetCameraControl(true)
	end
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:PrimaryAction(down)
	if not down or self:IsDead() or not self:IsGhostPlacementActive() then
		return
	end

	if (self.m_equippedItem:NKGetStackCount() == 1) then
		self.m_equippedItem:NKSetShouldRender(true, true)
		self.m_equippedItem:NKRemoveFromWorld(false, false)
	end
	self:TryPlaceAt(SurvivalInventoryManager.Containers.eHandSlot, 1, 1, self.m_ghostObject:NKGetPosition(), self.m_ghostObject:NKGetOrientation())
end

-------------------------------------------------------------------------------
-- Input Events
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function SurvivalPlacementInput:TogglePlacementMode(down)
	if not down or self:IsDead() then
		return
	end

	self.m_ghostPlacementActive = not self.m_ghostPlacementActive
	self:SetPlacementMode(self.m_ghostPlacementActive)
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:DropHandItem(down)
	if not down or self:IsDead() or not self:GetHandItem() then
		return
	end

	if self:IsGhostPlacementActive() then 
		self:TryPlaceAt(SurvivalInventoryManager.Containers.eHandSlot, 1, 0, self.m_ghostObject:NKGetPosition(), self.m_ghostObject:NKGetOrientation())
	else 
		self.m_equippedItem:NKSetShouldRender(true, true)
		self:TryPlace(SurvivalInventoryManager.Containers.eHandSlot, 1, 0, Eternus.GameState.m_activeCamera:NKGetLocation(), Eternus.GameState.m_activeCamera:ForwardVector())
	end
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:HandleMouse(dt)
	local ghostObj = self.m_ghostObject
	if not ghostObj then
		return true
	end

	local mouseDelta = Eternus.InputSystem:NKGetMouseAxis()
	local delta = { 
		x = (mouseDelta:x() * self.m_zPlacementSensitivity) * dt, 
		y = (mouseDelta:y() * self.m_zPlacementSensitivity) * dt 
	}

	local allowPlayerControl = true
	if Eternus.InputSystem:NKIsDown(EternusKeycodes.LCTRL) then
		local upVec = vec3.new(0.0, 1.0, 0.0)
		local fwdVec = EternusEngine.SurvivalMode.m_activeCamera:ForwardVector()
		fwdVec = vec3.new(fwdVec:x(), 0.0, fwdVec:z()):normalize()
		fwdVec = vec3.new(fwdVec:x() * -1.0, 0.0, fwdVec:z() * -1.0)
		local rightVec = fwdVec:cross(upVec)
		
		if Eternus.InputSystem:NKIsDown(EternusKeycodes.MOUSE_RCLICK) then
			local ghostRot = ghostObj:NKGetOrientation()
			ghostObj:NKSetOrientation(ghostRot:rotate(delta.x * -1.0, upVec))
		else
			local ghostRot = ghostObj:NKGetOrientation()
			ghostRot = ghostRot:rotate(delta.x, fwdVec)
			ghostRot = ghostRot:rotate(delta.y, rightVec)
			ghostObj:NKSetOrientation(ghostRot)
		end
		allowPlayerControl = false
	elseif Eternus.InputSystem:NKIsDown(EternusKeycodes.MOUSE_RCLICK) then
		local rayCastDist = MAX_RAYCAST_DISTANCE * ghostObj:NKGetPlaceable():NKGetTetherDistanceModifier()
		local tetherDistance = EternusEngine.SurvivalMode.state:NKGetTetherDistance()
		tetherDistance = tetherDistance - (delta.y + delta.y)
		if tetherDistance > rayCastDist then
			tetherDistance = rayCastDist
		elseif tetherDistance < 2.0 then
			tetherDistance = 2.0
		end
		EternusEngine.SurvivalMode.state:NKSetTetherDistance(tetherDistance)
		allowPlayerControl = false
	end
	
	-- This will disable the camera from looking around when doing something
	--	in placement that should prevent it. IE Rotating the object via holding
	--	the control key
	--NKPrint("AllowPlayerControl: " .. tostring(allowPlayerControl) .. "\n")
	self:SetCameraControl(allowPlayerControl)
end

-------------------------------------------------------------------------------
-- Public
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:TryPlace( _container, _index, _quantity, _origin, _direction )
	self:RaiseServerEvent("ServerEvent_Place", { 
		container = _container, 
		index = _index, 
		quantity = _quantity, 
		origin = _origin, 
		direction = _direction
	})
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:TryPlaceAt( _container, _index, _quantity, _worldPosition, _worldOrientation )
	self:RaiseServerEvent("ServerEvent_PlaceAt", { 
		container = _container, 
		index = _index, 
		quantity = _quantity, 
		position = _worldPosition, 
		orientation = _worldOrientation, 
		tKey = Eternus.InputSystem:NKIsDown(EternusKeycodes.t)
	})
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:TryDrop( _container, _index, _quantity, _origin, _direction )
	self:RaiseServerEvent("ServerEvent_DropInventoryItem", { 
		container = _container, 
		index = _index, 
		quantity = _quantity, 
		origin = _origin, 
		direction = _direction
	})
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:DropItem( _item )
	self:RaiseServerEvent("ServerEvent_DropItem", { 
		item = _item,
		origin = Eternus.GameState.m_activeCamera:NKGetLocation(), 
		direction = Eternus.GameState.m_activeCamera:ForwardVector()
	})
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:DropItemAt( _item, _origin, _direction )
	self:RaiseServerEvent("ServerEvent_DropItem", { 
		item = _item,
		origin = _origin, 
		direction = _direction
	})
end

-------------------------------------------------------------------------------
-- Drops a single item from the hand slot
function SurvivalPlacementLogic:TryPlaceHandItem( origin, direction, quantity )
	self:TryPlace(SurvivalInventoryManager.Containers.eHandSlot, 1, quantity, origin, direction)
end

-------------------------------------------------------------------------------
function SurvivalPlacementLogic:TryPlaceHandItemAt( worldPosition, worldOrientation, quantity )
	self:TryPlaceAt(SurvivalInventoryManager.Containers.eHandSlot, 1, quantity, worldPosition, worldOrientation)
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:ClientEvent_FailedPlace( args )
	-- set the placement mode to ghost
	self:SetPlacementMode(true)
	-- play sound
	self:NKGetSound():NKPlayLocalSound("InventoryFull", false)
end

-------------------------------------------------------------------------------
-- Drops a given object in front of the object this script is mixed into.
function SurvivalPlacementInput:DropItemInFrontOf(object)
	--self:DropItemAt(object, SOME_POSITION, quat.new(1.0,0.0,0.0,0.0))
end

function SurvivalPlacementInput:DropInventoryItem(container, index)
	self:TryDrop(container, index, 0, Eternus.GameState.m_activeCamera:NKGetLocation(), Eternus.GameState.m_activeCamera:ForwardVector())
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:GetGhostObject()
	return self.m_ghostObject
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:IsGhostPlacementActive()
	return self.m_ghostPlacementActive
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:GetZPlacementSensitivity()
	return self.m_zPlacementSensitivity
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:SetZPlacementSensitivity(to)
	self.m_zPlacementSensitivity = to
end

-------------------------------------------------------------------------------
-- Private
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function SurvivalPlacementInput:DropGhostObject()
	if self.m_ghostObject ~= nil then
		self.m_ghostObject:NKGetInstance().m_ghostObject = nil
		self:DropItemAt(self.m_ghostObject, self.m_ghostObject:NKGetPosition(), self.m_ghostObject:NKGetOrientation())
	end
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:VerifyState()
	if self.m_didPlace then 
		self.m_didPlace = false
		self:SetSecondaryActionEnabled(true)
		self:SetPrimaryActionEnabled(true)
		self:SetCameraControl(true)
	end
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:UpdateGhostPlacement(dt)
	if not self:IsGhostPlacementActive() then return end

	self:HandleMouse(dt)
	self:ProcessGhostObject(dt)
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:ProcessGhostObject(dt)
	local hookRet = CL:hook("SurvivalPlacementInput:ProcessObjectGhost",self)
	if (hookRet == CL.hooks.Abort) then
		return
	end
	
	--local ghostObj = self:GetObjectGhost()
	local ghostObj = self.m_ghostObject
	if not ghostObj then
		return
	end
	
	
	local fwdVec = EternusEngine.SurvivalMode.m_activeCamera:ForwardVector()
	local cameraThetaDelta = EternusEngine.SurvivalMode.m_activeCamera:NKGetDeltaTheta()
	local cameraPos = EternusEngine.SurvivalMode.m_activeCamera:NKGetLocation()
	
	-- Find the closest max distance
	local maxDistance = EternusEngine.SurvivalMode.state:NKGetTetherDistance() -- tetherDistance
	
	local rayResult = NKPhysics.RayCastCollectAll(cameraPos, fwdVec, maxDistance * 1.1, {self})
	local hitObject = nil
	local hitLoc = nil
	if rayResult then
		for key, hit in pairs(rayResult) do
			if (hit.distance < maxDistance) then
				maxDistance = hit.distance
				hitLoc = hit.contact
				hitObject = hit.gameobject
			end
		end
	end
	
	local hookRet = CL:hook("SurvivalPlacementInput:GhostHitObject", self, ghostObj:NKGetInstance(), hitObject, maxDistance, hitLoc)
	if (hookRet == CL.hooks.Abort) then
		return
	end
	
	local hitLoc = cameraPos + vec3.new(fwdVec:x() * maxDistance, fwdVec:y() * maxDistance, fwdVec:z() * maxDistance)
	
	if Eternus.InputSystem:NKIsDown(EternusKeycodes.t) == false then --Check if T is held
		-- Set the starting hit location to the max distance point in forward direction
		
		if (maxDistance > 0.1) then
			-- Find the closest "safe" location
			local traceResult = NKPhysics.ObjectSweepCollectAll(ghostObj, cameraPos, fwdVec, maxDistance * 1.1, {self}, 0.35)
			
			if traceResult then
				for key, hit in pairs(traceResult) do
					local currDist = math.abs((hitLoc - cameraPos):NKLength())
					local newDist = math.abs((hit.queryPosition - cameraPos):NKLength())
					if (newDist < currDist) then
						hitLoc = hit.queryPosition + (hit.normal:mul_scalar(0.01))
					end
				end
			end
		end
	end

	--local objRot = ghostObj:NKGetOrientation():rotate(cameraThetaDelta, vec3.new(0.0, 1.0, 0.0))

	--Add it to the world.  Make sure this is done AFTER scale
	local q = ghostObj:NKGetPlaceable():NKGetRotOffset()
	local rot = quat.new(0.0,0.0,1.0,0.0)
	 if q ~= quat.new(1.0,0.0,0.0,0.0) then
	 	GLM.Rotate(rot, q:w(), vec3.new(q:x(), q:y(), q:z()))
	 end


	local theta = EternusEngine.SurvivalMode.m_activeCamera:Theta()
	GLM.Rotate(rot, cameraThetaDelta, NKMath.Up)


	--ghostObj:NKSetOrientation(rot:normalize())	

	--ghostObj:NKSetOrientation(objRot:normalize())
	ghostObj:NKSetPosition(hitLoc, false)
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:SetPlacementMode(to)
	self.m_ghostPlacementActive = to 

	-- Enable special placement mode
	if to and self.m_equippedItem then 
		self:SetSecondaryActionEnabled(false)
		self:SetPrimaryActionEnabled(false)

		self:SetupGhostObject(self.m_equippedItem:NKGetName())

		if self.m_equippedItem:NKGetInstance():InstanceOf(PlaceableMaterial) then
			self.m_ghostObject:NKScale(NKMath.RangeMapping(self.m_equippedItem:NKGetStackCount(), 1.0, 100.0, 1.0, 2.5), false)
		end

		EternusEngine.SurvivalMode.state:NKSetTetherDistance((MAX_RAYCAST_DISTANCE * self.m_ghostObject:NKGetPlaceable():NKGetTetherDistanceModifier()) / 2.0)

		local durability = 0.0
		local handObjEquipable = self.m_equippedItem:NKGetEquipable()
		if handObjEquipable then
			durability = handObjEquipable:NKGetCurrentDurability()
			self.m_ghostObject:NKGetEquipable():NKSetCurrentDurability(durability, false)
		end
		
		self.m_ghostObject:NKSetShouldRender(true, true)
		local ghostObjEquipable = self.m_ghostObject:NKGetEquipable()
		if ghostObjEquipable then
			if self.m_equippedItem then
				self.m_equippedItem:NKSetShouldRender(false, true)
			end
		end
	else 
		-- Disable special placement mode

		self:SetSecondaryActionEnabled(true)
		self:SetPrimaryActionEnabled(true)

		self:SetupGhostObject("")

		if self.m_equippedItem then 
			self.m_equippedItem:NKSetShouldRender(true, true)
		end
	end
end

-------------------------------------------------------------------------------
function SurvivalPlacementInput:SetupGhostObject(objName)
	--NKPrint("Setting GhostObject: " .. objName .. "\n")
	if self.m_ghostObject then
		if self.m_ghostObject:NKGetName() == objName then
			return
		else
			self.m_ghostObject:NKRemoveFromWorld(true, false)
			self.m_ghostObject = nil
		end
	end
	
	if objName == "" then
		return
	end
	
	self.m_ghostObject = Eternus.GameObjectSystem:NKCreateGameObject(objName, true)
	self.m_ghostObject:NKGetInstance().m_ghostObject = true
	self.m_ghostObject:NKPlaceInWorld(false, false)

	local ghostPhysics = self.m_ghostObject:NKGetPhysics()
	

	if ghostPhysics then
		ghostPhysics:NKDisable() --RemoveFromWorld
	end
end

-------------------------------------------------------------------------------
-- Is setting m_ghostObject to nil enough?
function SurvivalPlacementInput:ClearGhostObject()
	self.m_ghostObject = nil

	-- Should it be...?
	--self:SetupGhostObject("")
end


return SurvivalPlacementInput