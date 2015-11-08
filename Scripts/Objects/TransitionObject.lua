include("Scripts/Objects/PlaceableObject.lua")

if (TransitionObject == nil) then
	TransitionObject = PlaceableObject.Subclass("TransitionObject")
end

function TransitionObject:Constructor( args )
	self.m_active = false
	self.m_timeLeft = 100
	self.m_targetName = nil
end

function TransitionObject:PostLoad()
	TransitionObject.__super.PostLoad(self)
	self.m_icon = nil
end

function TransitionObject:Spawn()
	TransitionObject.__super.Spawn(self)
	self:NKEnableScriptProcessing(true)
end

function TransitionObject:Update(dt)
	if (self.m_inInventory or self.m_ghostObject or not Eternus.IsServer or not self.m_active) then
		return
	end
	self.m_timeLeft = self.m_timeLeft - dt
	if self.m_timeLeft <= 0 then
		self:ConvertToNewObject()
	end
end

function TransitionObject:ConvertToNewObject()
	NKWarn("ConvertToNewObject: " .. tostring(self.m_targetName))
	
	local newObj = Eternus.GameObjectSystem:NKCreateNetworkedGameObject(self.m_targetName, true, true);
	
	newObj:NKSetOrientation(self:NKGetWorldOrientation())
	newObj:NKSetPosition(self:NKGetWorldPosition()+vec3(0,0.3,0), false)
	local newObjPhysics = newObj:NKGetPhysics()
	if (newObjPhysics ~= nil) then
		newObjPhysics:NKActivate()
	end
	newObj:NKPlaceInWorld(true, false)
	
	if (newObj.OnPlace ~= nil) then
		newObj:OnPlace()
	end
	self:NKDeleteMe()
end

-------------------------------------------------------------------------------
function TransitionObject:GetDebuggingText()
	local out = "Target: " .. tostring(self.m_targetName) .. " " .. tostring(CL.round(self.m_timeLeft,3).."s")
	return out
end

-------------------------------------------------------------------------------
function TransitionObject:SetTarget( targetName, timeLeft )
	if targetName then
		self.m_targetName = targetName
		self.m_timeLeft = timeLeft or 0.5
		self.m_active = true
	end
end

-------------------------------------------------------------------------------
function TransitionObject:Save( outData )
	TransitionObject.__super.Save(self, outData)
	if self.m_active then
		outData.targetName = self.m_targetName
		outData.timeLeft = self.m_timeLeft
		outData.active = self.m_active
	end
end

-------------------------------------------------------------------------------
function TransitionObject:Restore( inData, version )
	TransitionObject.__super.Restore(self, inData, version)
	if inData.active and inData.targetName then
		self.m_targetName = inData.targetName
		self.m_timeLeft = inData.timeLeft or 0.5
		self.m_active = inData.active
	else
		self:NKRemoveFromWorld(true, true, true)
	end
end

-------------------------------------------------------------------------------
EntityFramework:RegisterGameObject(TransitionObject)