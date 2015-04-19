include("Scripts/Core/Common.lua")
include("Scripts/Characters/BaseCharacter.lua")
include("Scripts/Mixins/ServerCraftingMixin.lua")
include("Scripts/Mixins/SurvivalPlacementLogic.lua")
include("Scripts/Mixins/ChatCommandsLogic.lua")
include("Scripts/Characters/3PModel.lua")
include("Scripts/Core/SurvivalInventoryManager.lua")
include("Scripts/Buffs/StatManager.lua")
include("Scripts/Buffs/Buffable.lua")
include("Scripts/Utils/PlayerFinderHelper.lua")
include("Scripts/Objects/Weapons/RangedWeapon.lua")
include("Scripts/Objects/Weapons/ThrowablePotion.lua")
include("Scripts/Objects/Gauntlet.lua")
include("Scripts/Objects/Shield.lua")

local NKPhysics = include("Scripts/Core/NKPhysics.lua")
local PlayerMetricsMixin = include("Scripts/Mixins/PlayerMetricsMixin.lua")

BasePlayer = BaseCharacter.Subclass("BasePlayer")


--[[										]]--
--[[	 Static variables (do not tweak!)	]]--
--[[										]]--
BasePlayer.EState =
{
	eWalking 	= 0,
	eRunning 	= 1,
	eIdle		= 2,
	eSneak 		= 12,
	eSneakRun	= 13,
	eCrouch		= 11,
	eFlying		= 15
}

BasePlayer.EStance =
{
	eDefault =
	{
		name = "Default",
		id = 1,
		allowPickup = true,
	},
	eHolding =
	{
		name = "Holding",
		id = 2,
	},
	eHoeing = 
	{
		name = "Hoeing",
		id = 3,
	},
	eSkinning =
	{
		name = "Skinning",
		id = 4,
	},
	eMining =
	{
		name = "Mining",
		id = 5,
	},
	eSlingshotHolding =
	{
		name = "SlingshotHolding",
		id = 6,
	},
	eSlingshotHolding2 =
	{
		name = "SlingshotHolding2",
		id = 7,
	},
	eHoldingPotion =
	{
		name = "HoldingPotion",
		id = 8,
	},
	eCasting =
	{
		name = "Casting",
		id = 9,
	},
	eCasting2 =
	{
		name = "Casting2",
		id = 10,
	},
	eChanneling =
	{
		name = "Channeling",
		id = 11,
	},
	eHoldingShield =
	{
		name = "HoldingShield",
		id = 12,
	},
}

BasePlayer.EStance.Lookup =
{
	[1] = BasePlayer.EStance.eDefault,
	[2] = BasePlayer.EStance.eHolding,
	[3] = BasePlayer.EStance.eHoeing,
	[4] = BasePlayer.EStance.eSkinning,
	[5] = BasePlayer.EStance.eMining,
	[6] = BasePlayer.EStance.eSlingshotHolding,
	[7] = BasePlayer.EStance.eSlingshotHolding2,
	[8] = BasePlayer.EStance.eHoldingPotion,
	[9] = BasePlayer.EStance.eCasting,
	[10] = BasePlayer.EStance.eCasting2,
	[11] = BasePlayer.EStance.eChanneling,
	[12] = BasePlayer.EStance.eHoldingShield,
}

BasePlayer.EStanceTransitions = 
{
	eHold = 
	{
		name = "Hold",
		id = 1
	},
	eCancel =
	{
		name = "Cancel",
		id = 2
	},
	eBackToDefault =
	{
		name = "BackToDefault",
		id = 3,
	},
	eThrow =
	{
		name = "Throw",
		id = 4,
	},
	eHoe   =
	{
		name = "Hoe",
		id = 5,
	},
	eSkin = 
	{
		name = "Skin",
		id = 6,
	},
	eSlingshotHold = 
	{
		name = "SlingshotHold",
		id = 7,
	},
	eShoot = 
	{
		name = "Shoot",
		id = 8,
	},
	eShootLast = 
	{
		name = "ShootLast",
		id = 9,
	},
	eHoldPotion =
	{
		name = "HoldPotion",
		id = 10,
	},
	eCast =
	{
		name = "Cast",
		id = 11,
	},
	eChannel =
	{
		name = "Channel",
		id = 12,
	},
	eHoldShield =
	{
		name = "HoldShield",
		id = 13,
	},
}

BasePlayer.EStanceTransitions.Lookup =
{
	[1] = BasePlayer.EStanceTransitions.eHold,
	[2] = BasePlayer.EStanceTransitions.eCancel,
	[3] = BasePlayer.EStanceTransitions.eBackToDefault,
	[4] = BasePlayer.EStanceTransitions.eThrow,
	[5] = BasePlayer.EStanceTransitions.eHoe,
	[6] = BasePlayer.EStanceTransitions.eSkin,
	[7] = BasePlayer.EStanceTransitions.eSlingshotHold,
	[8] = BasePlayer.EStanceTransitions.eShoot,
	[9] = BasePlayer.EStanceTransitions.eShootLast,
	[10] = BasePlayer.EStanceTransitions.eHoldPotion,
	[11] = BasePlayer.EStanceTransitions.eCast,
	[12] = BasePlayer.EStanceTransitions.eChannel,
	[13] = BasePlayer.EStanceTransitions.eHoldShield,
}


BasePlayer.EStanceTransitions.LookupByName =
{
	["Hold"] = BasePlayer.EStanceTransitions.eHold,
	["Cancel"] = BasePlayer.EStanceTransitions.eCancel,
	["BackToDefault"] = BasePlayer.EStanceTransitions.eBackToDefault,
	["Throw"] = BasePlayer.EStanceTransitions.eThrow,
	["Hoe"] = BasePlayer.EStanceTransitions.eHoe,
	["Skin"] = BasePlayer.EStanceTransitions.eSkin,
	["Shoot"] = BasePlayer.EStanceTransitions.eShoot,
	["SlingshotHold"] = BasePlayer.EStanceTransitions.eSlingshotHold,
	["Shoot"] = BasePlayer.EStanceTransitions.eShoot,
	["ShootLast"] = BasePlayer.EStanceTransitions.eShootLast,
	["HoldPotion"] = BasePlayer.EStanceTransitions.eHoldPotion,
	["Cast"] = BasePlayer.EStanceTransitions.eCast,
	["Channel"] = BasePlayer.EStanceTransitions.eChannel,
	["HoldShield"] = BasePlayer.EStanceTransitions.eHoldShield,
}

BasePlayer.EPrimaryActionAnimation = 
{
	ePlace = 
	{
		name = "Place",
		id = 1
	},
	ePickup = 
	{
		name = "Pickup",
		id = 2
	},
	ePunch = 
	{
		name = "Punch",
		id = 3
	},
}


BasePlayer.EPrimaryActionAnimationLookup =
{
	[1] = BasePlayer.EPrimaryActionAnimation.ePlace,
	[2] = BasePlayer.EPrimaryActionAnimation.ePickup,
	[3] = BasePlayer.EPrimaryActionAnimation.ePunch,

} 


-- Default capsule sizes used by the seed and wisp
BasePlayer.Capsule = 
{
	SeedHeight 	= 2.5,
	SeedFeet 	= 0.2,
	SeedRadius 	= 0.7,
	WispRadius 	= 0.7
}

BasePlayer.CrouchCapsule = 
{
	SeedHeight 	= 1.0,
	SeedFeet 	= 0.2,
	SeedRadius 	= 0.7,
	WispRadius 	= 0.7
}

-------------------------------------------------------------------------------
BasePlayer.GrowthState =
{
	['Child'] =
	{
		Experience 		= 0.0,
		AgeMorph		= 0.0,
		CameraOffset 	= 3.2,
		SeedScale 		= 1.0
	},
	['Teen'] =
	{
		Experience 		= 4000.0,
		AgeMorph		= 1.0,
		CameraOffset 	= 4.2,
		SeedScale 		= 1.25
	}
}

-- Maximum (and starting) hp of the local player.
BasePlayer.MaxHealth 	= 100.0 

BasePlayer.HurtColor = "tl:FFFF0000 tr:FFFF0000 bl:FFFF0000 br:FFFF0000"

-- Name of the third person object to spawn as a child.
if Eternus.DevMode then
	BasePlayer.ThirdPersonObjectName		= "Cactus"
else
	BasePlayer.ThirdPersonObjectName		= "Player Seedling Male"
end

-- BlendSlot name for upper torso animations
BasePlayer.TorsoBlendSlotName			= "Upper Torso Slot"

-- BlendSlot name for full body animations
BasePlayer.FullBodyBlendSlotName		= "Full Body Slot"

-- Maximum (and starting) stamina of the player.
BasePlayer.MaxStamina					= 100.0

-- The transition time for animation blending
BasePlayer.DefaultAnimationBlendTime	= 0.1

-- Maximum (and starting) hunger of the player.
BasePlayer.MaxEnergy	= 100.0

-- Maximum encumbrance of the player.
BasePlayer.MaxEncumbrance = 36.0

-- Passive hunger decay per second of the player.
BasePlayer.EnergyRegenPerSecond		= -0.0666

-- Emitter to play when taking damage.
BasePlayer.HealthHitEmitterName		= "Combat Hit HP Emitter"

-- Respawn timer.
BasePlayer.RespawnTimerDuration = 15.0

-- The default step sound name to use.
BasePlayer.DefaultStepSound	= "StepStone"

BasePlayer.EquippedItemRendersLast = false

-- The default distance a seed can reach when placing / picking up / interacting
BasePlayer.DefaultMaxReachDistance = 6.0

-- The default distance a seed can collect info from an object
BasePlayer.DefaultMaxLookDistance = 25.0

-- The default damage the player's hand does to objects
BasePlayer.DefaultHandDamage = 5.0

-- The default animation played from a "swing"
BasePlayer.DefaultSwingAnimation = "Punch"

-------------------------------------------------------------------------------
-- How much durability weapons lose when they hit me
BasePlayer.DurabilityLossOnCorrectHit = 2
BasePlayer.DurabilityLossOnIncorrectHit = 8

-- The default hurt animation.  This is used to ensure we don't interrupt other
-- animations (which we need callbacks from for user actions) with the being hurt
-- animation.
BasePlayer.DefaultHurtAnimation = "Hurt"
BasePlayer.DefaultPunchSound    = "Punch"
BasePlayer.DefaultMissedPunchSound = "WeaponSwing"

BasePlayer.ThreeDSoundOffset = vec3.new(0, 0, 0)

NKRegisterEvent("Play3DSound",
	{ 
		sound = "string" 
	}
)

NKRegisterEvent("ServerEvent_TakeDamage", 
	{
		damage = "float",
		category = "string"
	}
)



NKRegisterEvent("ClientEvent_TakeDamage",
	{
	}
)

NKRegisterEvent("ClientEvent_Die",
	{
	}
)

NKRegisterEvent("NetEvent_Revive",
	{
		respawnPos = "vec3",
		experience = "int"
	}
)

NKRegisterEvent("ClientEvent_ItemEquipped",
	{
		equippedItem = "gameobject"
	}
)

NKRegisterEvent("ServerEvent_PrimaryAction",
	{
		positionW = "vec3",
		direction = "vec3",
	}
)

NKRegisterEvent("ServerEvent_PickupAction",
	{
		positionW = "vec3",
		direction = "vec3",
	}
)

NKRegisterEvent("ServerEvent_SecondaryAction",
	{
		positionW = "vec3",
		direction = "vec3",
	}
)

NKRegisterEvent("SharedEvent_TransitionStance",
	{
		transitionID = "int",
	}
)

NKRegisterEvent("SharedEvent_TransitionShield",
	{
		transitionID = "int",
		targetStanceID = "int",
	}
)

NKRegisterEvent("ServerEvent_ToggleHoldStance",
	{
	}
)

NKRegisterEvent("ServerEvent_Cast",
	{
	}
)

NKRegisterEvent("ServerEvent_PlayTorsoAnimOnce",
	{
		animName 	= "string",	
		TimeIN 		= "float",
		TimeOUT 	= "float",
		loop 		= "boolean",
		restart 	= "boolean",
	}
)

NKRegisterEvent("ClientEvent_PlayTorsoAnimOnce",
	{
		animName 	= "string",	
		TimeIN 		= "float",
		TimeOUT 	= "float",
		loop 		= "boolean",
		restart 	= "boolean",
	}
)

NKRegisterEvent("ServerEvent_SetStance", 
	{
		stanceID = "int",
	}
)

NKRegisterEvent("ClientEvent_SetStance", 
	{
		stanceID = "int",
	}
)

NKRegisterEvent("Server_Pickup",
	{
		name 	= "string",
		count 	= "int",
	}
)

NKRegisterEvent("ServerEvent_SetBlockBrush",
	{
		brushIdx = "int",
	}
)

NKRegisterEvent("ClientEvent_PlayMiningEmitter",
	{
		position = "vec3",
		name 	 = "string",
	}
)

-------------------------------------------------------------------------------
-- Netevent that makes a client apply the asthetics changes to the seed from an experience value.
NKRegisterEvent("Client_ApplyExperienceEffects",
	{
		experience = "int"
	}
)

-------------------------------------------------------------------------------
function BasePlayer:Constructor( args )
	self.m_state 					= BasePlayer.EState.eIdle
	self.m_stance 					= BasePlayer.EStance.eDefault
	self.m_movementLocked			= false
	self.m_actionsLocked			= false
	self.m_health 					= BasePlayer.MaxHealth
	self.m_stamina 					= BasePlayer.MaxStamina
	self.m_encumbrance 				= BasePlayer.MaxEncumbrance
	self.m_currentCapsule			= BasePlayer.Capsule
	self.m_energyTimer				= 0.0
	self.m_staminaTimer				= 0.0
	self.m_staminaUpdateInterval	= 0.05 -- 20 times a second.
	self.m_swingTimer				= 0.0
	self.m_holdingTorchTimer		= 0.0
	self.m_petMaxAmt				= 3.0  -- max number of pets allowed to follow the player
	self.m_petAmt					= 0.0  -- current number of pets
	self.m_petname					= nil
	
	self.m_shieldStance 			= Shield.EStance.eNoShield
	self.m_leftWeaponState			= 0
	
	if Eternus.IsServer then
		self.m_disconnectSignal 		= NKUtils.CreateSignal()
	end
	
	self.m_healthChangedEvent 		= NKUtils.CreateSignal()
	self.m_staminaChangedEvent 		= NKUtils.CreateSignal()
	self.m_expChangedSignal			= NKUtils.CreateSignal()
	
	self.m_staminaRegenRates = {}
	self.m_staminaRegenRates[BasePlayer.EState.eWalking]	= 29.66
	self.m_staminaRegenRates[BasePlayer.EState.eRunning]	= -3.26
	self.m_staminaRegenRates[BasePlayer.EState.eIdle]		= 29.66
	self.m_staminaRegenRates[BasePlayer.EState.eSneak]		= 0.0
	self.m_staminaRegenRates[BasePlayer.EState.eSneakRun]	= -4.96
	self.m_staminaRegenRates[BasePlayer.EState.eCrouch]		= 20.77
	self.m_staminaRegenRates[BasePlayer.EState.eFlying]		= 29.66
	self.m_staminaDrainOnSwing = -10.0
	self.m_staminaDrainOnJump  =  -4.0
	
	self.m_targetAcquiredSignal		= NKUtils.CreateSignal()
	self.m_targetLostSignal			= NKUtils.CreateSignal()
	self.m_targetHealthChangedSignal= NKUtils.CreateSignal()

	self.m_craftingStartSignal		= NKUtils.CreateSignal()
	self.m_craftingProgressSignal	= NKUtils.CreateSignal()
	self.m_craftingInterruptSignal	= NKUtils.CreateSignal()
	self.m_craftingStopSignal		= NKUtils.CreateSignal()

	self.m_diedSignal 				= NKUtils.CreateSignal()
	self.m_spawnedSignal			= NKUtils.CreateSignal()
	self.m_encumbranceChangedEvent  = NKUtils.CreateSignal()
	self.m_toggleInventorySignal	= NKUtils.CreateSignal()
	self.m_pendingDeath 			= false
	self.m_inDeathForm 				= false
	self.m_dying 					= false
	self.m_respawnCounter 			= 0.0
	self.m_equippedItem				= nil
	
	self.m_gfx						= nil
	self.m_torsoAnimationSlot 		= nil
	self.m_fullBodyAnimationSlot 	= nil
	self.m_stanceGraph				= nil
	self.m_speed 					= 0.0
	self.m_moveDir					= vec3.new(0.0, 0.0, 0.0)
	self.m_jumping					= false
	self.m_onGround					= true
	
	self.m_stepTimeAccumulator		= 0.0
	self.m_stepTimer				= 0.0

	self.m_isCrouching				= false
	self.m_isFlying 				= false
	
	self.m_maxReachDistance			= BasePlayer.DefaultMaxReachDistance
	self.m_maxLookDistance 			= BasePlayer.DefaultMaxLookDistance	

	self.m_handDamage				= BasePlayer.DefaultHandDamage
	self.m_unequippedSwing			= BasePlayer.DefaultSwingAnimation

	self.m_playerName 				= "Player"
	self.m_gear 					= nil

	if Eternus.IsServer then
		self:Mixin(ServerCraftingMixin, args)
		self:Mixin(ChatCommandsLogic, args)
		self:Mixin(PlayerMetricsMixin, args)
	end
	
	self.m_showInventory = false

 	self:Mixin(SurvivalInventoryManager, args)
 	self:Mixin(StatManager, args)
 	self:Mixin(Buffable, args)
 	self:Mixin(SurvivalPlacementLogic, args)

 	-- For duhBugging!
 	self:Mixin(PlayerFinderHelper, args)
	
	-- Speed stat is only USED by the client, but must be modified
	-- by the server.
	local speedStat = self:AddStat("SpeedMultiplier", 1.0, {min = 0.0})
	if speedStat then
		speedStat:SubscribeToValueChangeSignal(function (old, new) 
			self:OnSpeedChanged(old, new)
		end)
	end

	self.m_energy = self:AddStat("Energy", self.MaxEnergy, {min = 0.0, max = self.MaxEnergy})
	
	self.m_playerIsServer = false

	--Prototype for Block brush class
	self.BlockBrush = {}
	self.BlockBrush[1] = {}
	self.BlockBrush[1].Dimensions 	= vec3.new(1.0,1.0,1.0)
	self.BlockBrush[1].Color		= NKColors.WHITE
	self.BlockBrush[1].Shape     	= EternusEngine.Terrain.EVoxelBrushShapes.eCube
	self.BlockBrush[2] = {}
	self.BlockBrush[2].Dimensions 	= vec3.new(2.0,2.0,2.0)
	self.BlockBrush[2].Color		= NKColors.WHITE
	self.BlockBrush[2].Shape     	= EternusEngine.Terrain.EVoxelBrushShapes.eCube

 	self.CurrentBlockBrushIdx = 1
 	self.CurrentBlockBrush = self.BlockBrush[self.CurrentBlockBrushIdx]

 	self.m_obesity 					= 0--math.random(0.0, 1.0)
	self.m_hairIdx					= math.random(1, #ThirdPersonModel.ESlots['Hair'])

	-- Experience value is server-side only right now
	if Eternus.IsServer then
		self.m_experience				= 0.0
	end
end

-------------------------------------------------------------------------------
function BasePlayer:OnSpeedChanged( oldValue )
	local newValue = self:GetStat("SpeedMultiplier")
end

-------------------------------------------------------------------------------
function BasePlayer:PostLoad()
	if Eternus.IsServer then
		self:NKSetShouldSaveChildren(false)
		self:SetModelSeedling( self.m_experience )
	end
end

-------------------------------------------------------------------------------
function BasePlayer:InitializePawn()
	if self.m_connection then
		self.m_playerName = self.m_connection:NKGetPlayerName()
	end
end

-------------------------------------------------------------------------------
function BasePlayer:Spawn()
	self:NKSetControllerCapsuleSize(self.m_currentCapsule.SeedHeight, self.m_currentCapsule.SeedRadius)
	self:NKEnableScriptProcessing(true)
end

-------------------------------------------------------------------------------
function BasePlayer:Update( dt )
	if self.m_pendingDeath then
		-- Never repeat this function
		self.m_dying = false
		self.m_pendingDeath = false
		self:SetModelWisp()
	end

	if not self.m_inDeathForm then
		if self:IsCrouching() then
			if self.m_currentCapsule ~= self.CrouchCapsule then
				self.m_currentCapsule = self.CrouchCapsule
				self:NKSetControllerCapsuleSize(self.m_currentCapsule.SeedHeight, self.m_currentCapsule.SeedRadius)
			end
		else
			if self.m_currentCapsule ~= self.Capsule then
				self.m_currentCapsule = self.Capsule
				self:NKSetControllerCapsuleSize(self.m_currentCapsule.SeedHeight, self.m_currentCapsule.SeedRadius)
			end
		end
	end

	if Eternus.IsServer then

		-- Update the player's hunger.
		self:_UpdateEnergy(dt)
		self:_UpdateStamina(dt)
		if self:IsDead() then
			self.m_respawnCounter = self.m_respawnCounter + dt
			if self.m_respawnCounter > self.RespawnTimerDuration then
				-- revive
				self:_SetHealth(self.MaxHealth)
				self:_SetEnergy(self.MaxEnergy)
				self:RaiseNetEvent("NetEvent_Revive", { respawnPos = self.m_connection:NKGetRespawnLocation(), experience = self.m_experience })
				self.m_respawnCounter = 0.0
			end
		end
	end
	
	if self.m_gfx then
		self:_UpdateAnimationBlending()
	end
	
	self:UpdateStepSounds(dt)

	-- This needs to be flipped around to not always be decrementing this timer!!!!
	--	Set by SwingEquippedItem
	self.m_swingTimer = self.m_swingTimer - dt
	
	self.m_holdingTorchTimer = self.m_holdingTorchTimer + dt
	
	if self.m_holdingTorchTimer > 0.2 then
		if Eternus.IsServer then
			if self.m_equippedItem and self.m_equippedItem:NKGetInstance() and self.m_equippedItem:NKGetInstance():InstanceOf(Equipable) then
				local eqScript = self.m_equippedItem:NKGetInstance()
				if eqScript.m_category == "Torch" then
					Eternus.EventSystem:NKBroadcastEventInRadius("Event_PlayerHoldingTorch", self.object:NKGetPosition(), 20.0, self)
				elseif eqScript.m_category == "Meat" then
					Eternus.EventSystem:NKBroadcastEventInRadius("Event_PlayerHoldingMeat", self.object:NKGetPosition(), 20.0, self)
				elseif eqScript.m_category == "Edible" and not eqScript.TorchSound then  -- make sure this in not an edible torch!
					Eternus.EventSystem:NKBroadcastEventInRadius("Event_PlayerHoldingEdible", self.object:NKGetPosition(), 30.0, self)
				end
			end
		end
		self.m_holdingTorchTimer = 0
	end
end

-------------------------------------------------------------------------------
function BasePlayer:NetSerializeConstruction( writer )
	writer:NKWriteInt(self.m_stance.id)
	writer:NKWriteInt(self.m_shieldStance.id)

	if self.m_equippedItem then
		writer:NKWriteBool(true)
		writer:NKWriteGameObject(self.m_equippedItem)
	else
		writer:NKWriteBool(false)
	end

	writer:NKWriteString(self.m_playerName)
	writer:NKWriteDouble(self.m_obesity)
	writer:NKWriteInt(self.m_hairIdx)
	writer:NKWriteInt(self.m_experience)
end

-------------------------------------------------------------------------------
function BasePlayer:NetDeserializeConstruction( reader )

	local stance = 				BasePlayer.EStance.Lookup[reader:NKReadInt()]
	local shieldStance = 		Shield.EStance.Lookup[reader:NKReadInt()]

	if reader:NKReadBool() then
		self.m_equippedItem = 	reader:NKReadGameObject()
	end

	self.m_playerName = 		reader:NKReadString()


	local obesity = reader:NKReadDouble()
	local hairIdx = reader:NKReadInt()
	local experience = reader:NKReadInt()

	self:_UpdateGearVisuals( obesity, nil, hairIdx )
	self:SetModelSeedling( experience )
	self:RefreshInvGear()

	if self.m_equippedItem then 
		self:EquipItem(self.m_equippedItem)
	end

	local stanceValid = self.m_stanceGraph:NKSetState(stance.name)
	if stanceValid then
		self.m_stance = stance
	end
	
	stanceValid = self.m_shieldGraph:NKSetState(shieldStance.name)
	if stanceValid then
		self.m_shieldStance = shieldStance
	end

end

function BasePlayer:_UpdateGearVisuals( obesity, age, hairIdx )
	self.m_obesity = obesity or self.m_obesity
	age = age or 0.0
	self.m_hairIdx = hairIdx or self.m_hairIdx

	if self.m_3pobject then
		self.m_3pobject:SetDefaultAppearance(self.m_obesity, age, self.m_hairIdx)
	end
end

-------------------------------------------------------------------------------
function BasePlayer:UpdateStepSounds( dt )
	if Eternus.IsClient then
		-- Bail if the sound system is unready or we are dead.
		if not Eternus.SoundSystem:NKIsInitialized() or self.m_inDeathForm then
			return
		end

		-- Accumulate time.
		self.m_stepTimeAccumulator = self.m_stepTimeAccumulator + dt

		-- Make sure it's time for the next step.
		if self.m_stepTimeAccumulator < self.m_stepTimer then
			return
		end

		-- Keep any leftover time in the accumulator.
		self.m_stepTimeAccumulator = 0.0

		-- Compute the time till the next step based on the players state.
		if self.m_state == BasePlayer.EState.eWalking then
			self.m_stepTimer = 0.35
		elseif self.m_state == BasePlayer.EState.eRunning then
			self.m_stepTimer = 0.27
		elseif self.m_state == BasePlayer.EState.eSneakRun then
			self.m_stepTimer = 0.37
		elseif self.m_state == BasePlayer.EState.eSneak then
			self.m_stepTimer = 0.5
		else
			self.m_stepTimer = 0.0
			self.m_stepTimeAccumulator = 0.0
		end

		-- Give derived classes an opportunity to prevent step sounds. Though the timer above should run regardless.
		if self.m_stepTimer == 0.0 or not self:ShouldPlayStepSounds() then
			return
		end
		-- Give derived classes an opportunity to override the step sound.
		local soundName = self:GetCurrentStepSound()
			
		self:NKGetSound():NKPlay3DSound(soundName, false, vec3.new(0.0, 0.0, 0.0), 15.0, 135.0)
		self.m_prevStepSound = sound
	end
end

-------------------------------------------------------------------------------
-- Sets the player's controller to a crouching state and communicates it across
-- the network if needed.
function BasePlayer:SetCrouching( to )
	if to and not self:IsCrouching() then 
		self.m_isCrouching = true
	elseif not to and self:IsCrouching() then
		self.m_isCrouching = false
	end
end

-------------------------------------------------------------------------------
-- Sets the player's controller to a flying state and communicates it across
-- the network if needed.
function BasePlayer:SetFlying( to )
	if to and not self:IsFlying() then
		self.m_isFlying = true
		self:NKGetCharacterController():EnableFlying()
	elseif not to and self:IsFlying() then 
		self.m_isFlying = false
		self:NKGetCharacterController():DisableFlying()
	end
end

-------------------------------------------------------------------------------
-- Provides the name of the step sound to play when moving.
-- Derived classes should override this function to provide different stepsounds.
function BasePlayer:GetCurrentStepSound( )
	return self.DefaultStepSound	
end

-------------------------------------------------------------------------------
-- Returns true if this character is currently in a state where he should play a step sound.
-- Derived classes should override this function to provide different logic.
function BasePlayer:ShouldPlayStepSounds( )
	return self.m_state == BasePlayer.EState.eWalking 
		or self.m_state == BasePlayer.EState.eRunning
		or self.m_state == BasePlayer.EState.eSneakRun
		or self.m_state == BasePlayer.EState.eSneak
end

-------------------------------------------------------------------------------
-- Called once a frame to update the BlendInfo struct that drives the animated model.
function BasePlayer:_UpdateAnimationBlending( )
	-- Figure out the weapon state (none, one-handed, or two-handed)
	local weaponState = 0
	if self.m_equippedItem then
		-- We add one here so that one-handed and none are not the same.
		local eq = self.m_equippedItem:NKGetEquipable()
		if eq then
			weaponState = self.m_equippedItem:NKGetEquipable():NKGetHandleType() + 1
		end
	end

	-- Figure out the crouching state of the player.
	local crouchState = 1
	if self:IsCrouching() then
		crouchState = 0
	end
	

	-- Get the BlendInfo struct that drives the animation blend tree.
	local blendInfo = self.m_gfx:GetBlendInfo()

	-- Set the gameplay state.
	blendInfo:NKSetState("PlayerState", self.m_state)
	blendInfo:NKSetState("WeaponState", weaponState)
	blendInfo:NKSetState("CrouchState", crouchState)
	blendInfo:NKSetState("LeftWeaponState", self.m_leftWeaponState )
	
	-- Set the movement speed.
	blendInfo:NKSetSpeed(self.m_speed)

	-- Set the facing direction.
	blendInfo:NKSetFacingDirection(vec3.new(0.0, 0.0, 1.0):mul_quat(self:NKGetOrientation()))

	-- Set the movement direction (differs from facing due to strafing)
	blendInfo:NKSetMovementDirection(self.m_moveDir)

	-- TODO: NetworkingDev
	blendInfo:NKSetJumpFlag(self.m_jumping)

	-- Set the on ground status.
	if self.m_onGround or self.m_state == BasePlayer.EState.eFlying then
		blendInfo:NKSetOnGround(true)
	else
		blendInfo:NKSetOnGround(false)
	end
end

-------------------------------------------------------------------------------
-- Helper to set the the third-person GamObject on this player.
-- Additionally any previous third-person GameObject will be destroyed.
function BasePlayer:_SetThirdPersonGameObject( gameObjectName )
	-- If we already have a third person gameobject.
	if self.m_3pobject then
		-- Destroy it.

		if self.m_3pobject:NKGetInstance() then
			self:NKRemoveChildObject(self.m_3pobject.object)
		else
			self:NKRemoveChildObject(self.m_3pobject)
		end

		self.m_3pobject:NKRemoveFromWorld(true, false)

		-- Clear all our cached references to it.
		self.m_gfx = nil
		self.m_torsoAnimationSlot = nil
		self.m_fullBodyAnimationSlot = nil
	end

	-- Create the new one.
	self.m_3pobject = Eternus.GameObjectSystem:NKCreateGameObject(gameObjectName, true)

	-- If the object is nil, then most likely it was disabled in the manifest, or something went horribly wrong
	if not self.m_3pobject then
		NKPrint("Could not find the BasePlayer GameObject " .. gameObjectName .. "\n")
		return
	end

	self.m_3pobject:NKPlaceInWorld(false, false)
	self:NKAddChildObject(self.m_3pobject)

	-- If m_3pobject has a script, self.m_3pobject will point to its lua table. Otherwise the native object.
	if self.m_3pobject:NKGetInstance() then
		self.m_3pobject = self.m_3pobject:NKGetInstance()
	end

	-- If this object didnt have an animated model.
	self.m_gfx = self.m_3pobject:NKGetAnimatedGraphics()
	if not self.m_gfx then
		NKPrint("Unable to obtain third person animated graphics!\n")
		return
	end

	-- Look for the Upper Torso Animation node.
	self.m_torsoAnimationSlot = self.m_gfx:NKGetBlendSlot(self.TorsoBlendSlotName)

	-- Look for the Full Body node.
	self.m_fullBodyAnimationSlot = self.m_gfx:NKGetBlendSlot(self.FullBodyBlendSlotName)

	-- Find the stance state machine node.
	self.m_stanceGraph = self.m_gfx:NKGetBlendGraph("Stance Node")
	
	-- Register the state changed event on the stance graph.
	if self.m_stanceGraph then
		self.m_gfx:NKRegisterTransitionListener(self.m_stanceGraph, LuaAnimationCallbackListener.new(self, "OnStanceChanged"))
	end
	
	

	-- Find the stance state machine node.
	self.m_shieldGraph = self.m_gfx:NKGetBlendGraph("Shield Graph")
	
	-- Register the state changed event on the stance graph.
	if self.m_shieldGraph then
		self.m_gfx:NKRegisterTransitionListener(self.m_shieldGraph, LuaAnimationCallbackListener.new(self, "OnShieldStanceChanged"))
	end

	-- Setup the death callback.
	if self.m_fullBodyAnimationSlot then
		self.m_gfx:NKRegisterAnimationEvent("OnDeath", LuaAnimationCallbackListener.new(self, "OnDeathAnimationComplete"))
	end
end

-------------------------------------------------------------------------------
--  Called once a frame to update the state of the player's energy.
function BasePlayer:_UpdateEnergy( dt )
	-- Don't care about energy if we are dead.
	if self:IsDead() then
		return
	end
		
	-- Increment the one second energy timer.
	self.m_energyTimer = self.m_energyTimer + dt

	-- If it's time to tick energy.
	if self.m_energyTimer >= 1.0 then

		self:_ModifyEnergy(BasePlayer.EnergyRegenPerSecond)

		-- Reset the timer
		-- TODO: Aren't we losing any overflow time from the current dt by doing it this way?
		self.m_energyTimer = 0.0

		-- Are we starving?
		if self.m_energy:Value() <= 0.0 then
			self:RaiseServerEvent("ServerEvent_TakeDamage", { damage = 1.0, category = "Starving" })
		else
			-- TODO: needs porting
			--m_status &= ~eStatusStarving;
		end
	end
end

function BasePlayer:_UpdateStamina( dt )
	if self:IsDead() then
		return
	end
	
	-- Don't even increment the timer while we're not on the ground.
	if not self.m_onGround then
		return
	end
	
	-- Increment the stamina timer.
	self.m_staminaTimer = self.m_staminaTimer + dt
	
	-- Why is this a while loop?
	-- Why are we not updating stamina everyframe?
	-- Why only 20 times a second?
	while self.m_staminaTimer >= self.m_staminaUpdateInterval do
		
		local modAmount = self.m_staminaRegenRates[self.m_state]
		if not modAmount then
			return
		end
		modAmount = modAmount * self.m_staminaUpdateInterval
		self.m_staminaTimer = self.m_staminaTimer - self.m_staminaUpdateInterval
		self:_ModifyStamina(modAmount)
	end
end

-------------------------------------------------------------------------------
--function BasePlayer:PlayTorsoAnimationOneShot( animationID, animationName, transitionInTime, transitionOutTime, loop, restart)
function BasePlayer:PlayTorsoAnimationOneShot( animationName, transitionInTime, transitionOutTime, loop, restart )
	if not loop then loop = false end
	if not restart then restart = false end
	if self.m_torsoAnimationSlot then
		local curAnim = self.m_torsoAnimationSlot:GetPlayingAnimation()
		if (curAnim ~= nil and animationName == self.DefaultHurtAnimation) then
			return
		end
		self.m_torsoAnimationSlot:PlayCustomAnim(self.m_gfx:GetAnimation(animationName), transitionInTime, transitionOutTime, loop, restart)
	else
		NKPrint("Attempting to play animation on seedling without a valid animation slot!\n")
	end
end

-------------------------------------------------------------------------------
function BasePlayer:ClearTorsoAnimation( )
	if self.m_torsoAnimationSlot then
		self.m_torsoAnimationSlot:NKClearAnimation()
	end
end

-------------------------------------------------------------------------------
function BasePlayer:PlayFullBodyAnimationOneShot( animationName, transitionInTime, transitionOutTime )
	if self.m_fullBodyAnimationSlot then
		self.m_fullBodyAnimationSlot:PlayCustomAnim(self.m_gfx:GetAnimation(animationName), transitionInTime, transitionOutTime, false, false)
	else
		NKPrint("Attempting to play animation on seedling without a valid animation slot!\n")
	end
end

-------------------------------------------------------------------------------
function BasePlayer:GetThirdPersonModel( )
	return self.m_gfx
end

------------------------------------------------------------------------
function BasePlayer:GetActiveModel( )
	return self.m_3pobject.object
end

-------------------------------------------------------------------------------
-- Returns true if the player is currently in one of the crouched states.
function BasePlayer:IsCrouching( )
	return self.m_isCrouching
end

-------------------------------------------------------------------------------
-- Returns true if the player is currently set to a flying state
function BasePlayer:IsFlying( )
	return self.m_isFlying
end

-------------------------------------------------------------------------------
-- Returns true if the player is currently dying or a wisp.
function BasePlayer:IsDead( )
	return self.m_inDeathForm
end

-------------------------------------------------------------------------------
function BasePlayer:HasDied( )
	return self.m_inDeathForm or self.m_dying
end

-------------------------------------------------------------------------------
-- Helper to return whether this player is in the default stance (i.e. not holding a spear, shoveling, or hoeing.)
function BasePlayer:InDefaultStance( )
	return self.m_stance.id == BasePlayer.EStance.eDefault.id
end

-------------------------------------------------------------------------------
-- Helper to return whether this player is in the throwing stance
function BasePlayer:InHoldingStance( )
	return self.m_stance == BasePlayer.EStance.eHolding or self.m_stance == BasePlayer.EStance.eHoldingPotion
end

-------------------------------------------------------------------------------
-- Helper to return whether this player is in the slingshot holding stance
function BasePlayer:InSlingshotHoldingStance( )
	return (self.m_stance == BasePlayer.EStance.eSlingshotHolding) or (self.m_stance == BasePlayer.EStance.eSlingshotHolding2)
end

-------------------------------------------------------------------------------
-- Helper to return whether this player is in the casting stance
function BasePlayer:InCastingStance( )
	return (self.m_stance == BasePlayer.EStance.eCasting) or (self.m_stance == BasePlayer.EStance.eCasting2) or (self.m_stance == BasePlayer.EStance.eChanneling)
end

-------------------------------------------------------------------------------
-- Helper to return whether this player is in the channeling stance
function BasePlayer:InChannelingStance( )
	return (self.m_stance == BasePlayer.EStance.eChanneling)
end

-------------------------------------------------------------------------------
-- Helper to return whether this player is in the channeling stance
function BasePlayer:InHoldingShieldStance( )
	return (self.m_shieldStance == Shield.EStance.eBlocking)
end

-------------------------------------------------------------------------------
-- Returns true if this player is currently in a transition (blend or animation).
function BasePlayer:IsTransitioning( )
	return self.m_stanceGraph:NKIsTransitioning()
end

-------------------------------------------------------------------------------
-- Returns true if this player is currently in a transition (blend or animation).
function BasePlayer:IsShieldTransitioning( )
	return self.m_shieldGraph:NKIsTransitioning()
end

-------------------------------------------------------------------------------
function BasePlayer:NetSerialize( netWriter )
	netWriter:NKWriteDouble(self.m_health)
	netWriter:NKWriteDouble(self.m_energy:Value())
	netWriter:NKWriteDouble(self.m_energy:Max())
	netWriter:NKWriteDouble(self.m_stamina)

	if self.m_equippedItem then
		netWriter:NKWriteBool(true)
		netWriter:NKWriteObjectId(self.m_equippedItem:NKGetNetId())
	else
		netWriter:NKWriteBool(false)
	end
	
	-- Write the speed modifier out here.
	if self:GetStat("SpeedMultiplier") then
		
		netWriter:NKWriteDouble(self:GetStat("SpeedMultiplier"):Value())
		netWriter:NKWriteDouble(self:GetStat("SpeedMultiplier"):GetBase())
	else
		netWriter:NKWriteDouble(1.0)
		netWriter:NKWriteDouble(1.0)
	end
	
	netWriter:NKWriteInt(self.m_leftWeaponState)
end

-------------------------------------------------------------------------------
function BasePlayer:NetDeserialize( netReader )
	self:_SetHealth( netReader:NKReadDouble() )
	self:_SetEnergy( netReader:NKReadDouble() )
	local maxEnergy = netReader:NKReadDouble()
	self.m_energy:Synchronize({max = maxEnergy})
	self:_SetStamina( netReader:NKReadDouble() )

	if netReader:NKReadBool() then
		local eqItem = Eternus.World:NKGetGameObjectByNetId(netReader:NKReadObjectId())
		if self.m_equippedItem ~= eqItem then
			self.m_equippedItem =  eqItem
			if self.m_equippedItem then 
				self:EquipItem(self.m_equippedItem)
			end
		end
	end
	
	local speedCalc = netReader:NKReadDouble()
	local speedBase = netReader:NKReadDouble()
	if self:GetStat("SpeedMultiplier") then
		self:GetStat("SpeedMultiplier"):Synchronize({base = speedBase, calc = speedCalc})
	end
	
	self.m_leftWeaponState = netReader:NKReadInt()
end

-------------------------------------------------------------------------------
function BasePlayer:ServerEvent_TakeDamage( args )
	if not Eternus.IsServer then
		return
	end
	
	if args.damage then
		local previousHealth = self.m_health;
		local damaged = self:Server_TakeDamage(args)
		if self.m_health > 0.0 then
			if damaged then
				self:RaiseClientEvent("ClientEvent_TakeDamage", {})
			end
		else
			if previousHealth > 0.0 then
				self:RaiseClientEvent("ClientEvent_Die", {})
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Client side death/damage logic
if Eternus.IsClient then
	-------------------------------------------------------------------------------
	function BasePlayer:ClientEvent_TakeDamage( args )
		-- Play an emitter here.
		self:PlayerEmitterAtPosition(self.HealthHitEmitterName)
		
		--Also need to play an animation, but need animated models to be loading properly here first.
		self:PlayTorsoAnimationOneShot("Hurt", self.DefaultAnimationBlendTime, self.DefaultAnimationBlendTime)
		self:NKGetSound():NKPlay3DSound("SeedlingHurt", false, vec3.new(0, 0, 0), 15.0, 135.0)
	end

	-------------------------------------------------------------------------------
	function BasePlayer:ClientEvent_Die( args )
		-- Raise player death event
		self.m_diedSignal:Fire()
		self:Die()
	end

end -- Eternus.IsClient

-------------------------------------------------------------------------------
function BasePlayer:NetEvent_Revive( args )
	if args.respawnPos and self:InstanceOf(LocalPlayer) then -- Belongs in LocalPlayer via virtual function.
		local worldPlayer = self:NKGetWorldPlayer()
		if worldPlayer then
			worldPlayer:NKTeleportToLocation( args.respawnPos )
		end
	end

	self.m_inDeathForm = false
	self.m_pendingDeath = false

	self.m_spawnedSignal:Fire()

	if args.experience then
		self:SetModelSeedling( args.experience )
	end
end

-------------------------------------------------------------------------------
-- Modify the player's energy (hunger) by amount. Clamp to [0, m_maxEnergy].
function BasePlayer:_ModifyEnergy( amount )
	self:_SetEnergy(self.m_energy:Value() + amount)
end

-------------------------------------------------------------------------------
-- Sets the players energy (hunger) to a specific value. 
function BasePlayer:_SetEnergy( amount )
	self.m_energy:SetValue(amount)
end

-------------------------------------------------------------------------------
-- Modify the player's stamina by amount. Clamp to [0, m_maxStamina].
function BasePlayer:_ModifyStamina( amount )
	self:_SetStamina(self.m_stamina + amount)
end

-------------------------------------------------------------------------------
-- Sets the players stamina to a specific value. 
function BasePlayer:_SetStamina( amount )
	-- Modify then clamp new stamina value.
	self.m_stamina = NKMath.Clamp(amount, 0.0, self.MaxStamina)	
	self.m_staminaChangedEvent:Fire()
end

-------------------------------------------------------------------------------
function BasePlayer:Server_TakeDamage( args )
	if not Eternus.IsServer then
		return false
	end
	
	
	-- If modifying health doesn't matter if we are already dead
	if self:HasDied() or self:IsDead() then
		return false
	end
	
	
	args.category = EternusEngine.DamageManager.GetCategory( args.category )
	
	--if self.m_equippedItem and self.m_equippedItem:NKGetInstance():InstanceOf(Equipable) then
		local armsEq = self.m_inventoryContainers[SurvivalInventoryManager.Containers.eGearSlots]:GetItemAt(CharacterGear.ESlotsLUT["Arms"])
		
		if armsEq and armsEq.m_item and armsEq.m_item:NKGetInstance().AbsorbDamage then
			successfullyUsed = armsEq.m_item:NKGetInstance():AbsorbDamage(self, args)
		end
	
	--end
	
	if args.damage <= 0 then
		return false
	end
	
	-- Do effects here
	self:_ModifyHealth(-args.damage)
	return true
end

-------------------------------------------------------------------------------
function BasePlayer:_ModifyHealth( amount )
	self:_SetHealth(self.m_health + amount)
end

-------------------------------------------------------------------------------
function BasePlayer:_SetHealth( health )
	-- Clamp health between 0 and maxHealth
	self.m_health = NKMath.Clamp(health, 0.0, self.MaxHealth)
	self.m_healthChangedEvent:Fire()
end

-------------------------------------------------------------------------------
-- Swap the 3P model (m_3pobject) out from a seedling to a wisp.
-- Sets m_inDeathForm to true.
function BasePlayer:SetModelWisp( )
	self.m_inDeathForm = true

	self:_SetThirdPersonGameObject("Wisp")
	
	-- Shrink the capsule for the wisp
	self:NKSetControllerCapsuleSize(0.1, BasePlayer.Capsule.WispRadius)
end

-------------------------------------------------------------------------------
-- Swap the 3P model (m_3pobject) out from a wisp to a seedling.
function BasePlayer:SetModelSeedling( experience )
	-- Create a seed and destroy the wisp.
	self:_SetThirdPersonGameObject(self.ThirdPersonObjectName)
	self:_UpdateGearVisuals()

	if Eternus.IsClient then
		self:_ApplyExperienceEffects( experience )
	end

	-- Reset the capsule back to the seedlings size.
	self:NKSetControllerCapsuleSize(BasePlayer.Capsule.SeedHeight,  BasePlayer.Capsule.SeedRadius)
end

-------------------------------------------------------------------------------
-- Provides the movement direction of this player since last frame.
-- Derived classes should override this function to provide different logic.
function BasePlayer:GetMovementDirection( )
	-- Cache a ref to the character controller.
	local cc = self:NKGetCharacterController()

	-- Use the CharacterController to tell us if we have tried to move since last frame.
	if cc:NKIsMoving() then
		return cc:NKGetMovementDirection():NKNormalize()
	else
		return vec3.new(0.0)
	end
end

-------------------------------------------------------------------------------
function BasePlayer:Die( source )
	-- Do nothing if we have already died
	if self:HasDied() then
		return
	end

	self:ResetStance()
	
	if self.m_fullBodyAnimationSlot then
		self.m_fullBodyAnimationSlot:NKPlayCustomAnimHold(self.m_gfx:GetAnimation("Death"), self.DefaultAnimationBlendTime, false)
	end  
	
	self.m_health = 0.0
	self.m_dying = true
end

-------------------------------------------------------------------------------
function BasePlayer:OnDeathAnimationComplete( )
	-- We cannot call SetModelWisp() directly here, because this is a callback
	-- originating from the current Self object, and SetModelWisp deletes the current Self object.
	self.m_pendingDeath = true
end

-------------------------------------------------------------------------------
function BasePlayer:SetMovementLock( lockFlag )
	self.m_movementLocked = lockFlag
end

-------------------------------------------------------------------------------
function BasePlayer:SetActionLock( lockFlag )
	self.m_actionsLocked = lockFlag
end

-------------------------------------------------------------------------------
-- Server primary action logic.
function BasePlayer:ServerEvent_PrimaryAction( args )
	if not Eternus.IsServer then
		return
	end
	
	-- no primary action while holding shield
	if self:InHoldingShieldStance() then
		return
	end
	
	if self:IsDead() then
		return
	end
	
	-- If our inventory is open, CEGUI will handle all the input
	-- This is hacky and should be resolved when we get a new input system
	if self.m_showInventory then
		return
	end

	args.player = self
	args.camManifold = self:CreatePlayerCameraRaycastHit(args.positionW, args.direction, self:GetMaxReachDistance())

	if args.camManifold then
		args.targetObj = args.camManifold.gameobject
		args.targetPoint = args.camManifold.contact
	else
		args.targetObj = nil 
		args.targetPoint = args.positionW + (args.direction * vec3.new(6.0, 6.0, 6.0))
	end
	
	if self:InCastingStance( ) then
		
		local handsEq = self.m_inventoryContainers[SurvivalInventoryManager.Containers.eGearSlots]:GetItemAt(CharacterGear.ESlotsLUT["Hands"]) -- "Hands"
		
		if handsEq and handsEq.m_item and handsEq.m_item:NKGetInstance():InstanceOf(Gauntlet) then
			handsEq.m_item:NKGetInstance():GearPrimaryAction(args)
		else
			self:ResetStance()
		end

	-- Order of operations for primary action:
	-- 1. Pick up target.
	-- 2. Use currently held item. (This includes swinging it!)
	
	--local pickedUp = false
	--if args.targetObj then
	--	pickedUp = self:Pickup(args.targetObj)
	--end

	-- If pick up failed, use held item.
	--if not pickedUp then
	elseif self.m_equippedItem and self.m_equippedItem:NKGetInstance() and self.m_equippedItem:NKGetInstance():InstanceOf(Equipable) then
		local eqScript = self.m_equippedItem:NKGetInstance()
		if eqScript.PrimaryAction then

			eqScript:PrimaryAction(args)
			self:_ModifyStamina(self.m_staminaDrainOnSwing)

			-- For data metric system - While carrying an equipable, we check if the Player defeated or skinned an AI character; check if the Player destroyed a placeable object
			-- local target = args.targetObj
			-- if target ~= nil then
			-- 	local targetScript = target:NKGetInstance()
			-- 	if targetScript ~= nil then
			-- 		if targetScript:InstanceOf(AICharacter)  then
			-- 			if self:IsCharacterDefeated(target) then
			-- 				self:OnSuccessfulDefeat(target)
			-- 			end
			-- 			if self:IsCharacterSkinned(target) then
			-- 				self:OnSuccessfulSkin(target)
			-- 			end	
			-- 		elseif targetScript:InstanceOf(PlaceableObject) then
			-- 			if self:IsObjectDestroyed(target) then
			-- 				self:OnSuccessfulDestroy(target)
			-- 			end
			-- 		end
			-- 	end
			-- end
		end
	else 
		self:AffectObject(args)
		self:_ModifyStamina(self.m_staminaDrainOnSwing)

		-- For data metric system - We check if the Player destroyed a placeable object with its strong bare hands
		-- local target = args.targetObj
		-- if self:IsObjectDestroyed(target) then
		-- 	self:OnSuccessfulDestroy(target)
		-- end
	end
	
	self.m_targetHealthChangedSignal:Fire(args.targetObj)
	--end	
end

-------------------------------------------------------------------------------
-- Server primary action logic.
function BasePlayer:ServerEvent_PickupAction( args )
	if not Eternus.IsServer then
		return
	end
	
	if self:IsDead() then
		return
	end
	
	-- If our inventory is open, CEGUI will handle all the input
	-- This is hacky and should be resolved when we get a new input system
	if self.m_showInventory then
		return
	end

	args.player = self
	args.camManifold = self:CreatePlayerCameraRaycastHit(args.positionW, args.direction, self:GetMaxReachDistance())

	if args.camManifold then
		args.targetObj = args.camManifold.gameobject
		args.targetPoint = args.camManifold.contact
	else
		args.targetObj = nil 
		args.targetPoint = args.positionW + (args.direction * vec3.new(6.0, 6.0, 6.0))
	end

	-- Order of operations for primary action:
	-- 1. Pick up target.
	-- 2. Use currently held item. (This includes swinging it!)
	
	local pickedUp = false
	if args.targetObj then
		pickedUp = self:Pickup(args.targetObj)
	end

	-- If pick up failed, use held item.
	if not pickedUp then
		--NKPrint("ServerEvent_PickupAction play sound.\n")
		self:RaiseClientEvent("ClientEvent_PlayLocalSound", { sound = "InventoryFull" }, { self.m_connection })
	end	

end

-------------------------------------------------------------------------------
function BasePlayer:AffectObject( args )
	if not args.camManifold or not args.targetObj then
		-- Not targeting something.  Play the whiff sound.
		self:RaiseClientEvent("ClientEvent_PlayWorldSound",
				{
					soundName = self.DefaultMissedPunchSound,
					loop = false,
					position = self:NKGetWorldPosition(),
					velocity = vec3.new(0.0, 0.0, 0.0),
					minDist = 15.0,
					maxDist = 35.0
				})
		return
	end

	local objInstance = args.targetObj:NKGetInstance()

	--If this is a PlaceableObject we need to handle it differently than characters
	if objInstance:InstanceOf(PlaceableObject) then
		-- Check to see if this is a resource item or an equipable we are affecting.
		-- If so, do nothing, as we got here because the C++ PrimaryActionSurvival didn't
		-- catch this (the user moved their mouse during the animation to select this item)
		if objInstance:IsResource() or objInstance:InstanceOf(Equipable) then
			return false
		end
		
		-- Play punch sound regardless of whether we can affect the object or not.
		self:RaiseClientEvent("ClientEvent_PlayWorldSound",
				{
					soundName = self.DefaultPunchSound,
					loop = false,
					position = objInstance:NKGetWorldPosition(),
					velocity = vec3.new(0.0, 0.0, 0.0),
					minDist = 15.0,
					maxDist = 35.0
				})
		
		-- Player hands can only damage tier 0 items
		if objInstance:GetTier() > 0 then
			return
		end 

		-- Play the emitter and sound effect for this object...
		objInstance:PlayObjectBreakEmitter(args.camManifold.contact, args.camManifold.normal)
		local removeSound = objInstance:GetRemovalSound()
		if removeSound then
			--local player = Eternus.GameState:GetPlayer()
			--if player then
			--	player:NKGetSound():NKPlay3DSound(removeSound, false, vec3.new(0, 0, 0), 10.0, 15.0)
			--end
		end
		--Modify hit points of the object we are looking at
		objInstance:ModifyHitPoints(-self.m_handDamage)

	elseif objInstance:InstanceOf(AICharacter) then

	end	
end

-------------------------------------------------------------------------------
function BasePlayer:CreatePlayerCameraRaycastHit( origin, direction, distance )
	if not distance then 
		distance = EternusEngine.MAX_RAYCAST_DISTANCE
	end
	return NKPhysics.RayCastCollect(origin, direction, distance, {self})
end

-------------------------------------------------------------------------------
-- Server secondary action logic.
-- Priority for secondary actions:
-- 1. Use held object on target.
-- 2. Interact with target.
-- 3. Place held object.
function BasePlayer:ServerEvent_SecondaryAction( args )
	if not Eternus.IsServer then
		return
	end
	
	if self:IsDead() then
		return
	end
	
	-- If our inventory is open, CEGUI will handle all the input
	-- This is hacky and should be resolved when we get a new input system
	if self.m_showInventory then
		return
	end

	args.player = self
	args.camManifold = self:CreatePlayerCameraRaycastHit(args.positionW, args.direction, self:GetMaxReachDistance())

	if args.camManifold then
		args.targetObj = args.camManifold.gameobject
		args.targetPoint = args.camManifold.contact
	else
		args.targetObj = nil 
		args.targetPoint = args.positionW + (args.direction * vec3.new(6.0, 6.0, 6.0))
	end
	-- Attempt to use held object on target.  Object MUST report success
	-- or failure of this operation!
	local successfullyUsed = false
	local isEquipable = false
	if self.m_equippedItem then
		local eqScript = self.m_equippedItem:NKGetInstance()
		isEquipable = eqScript:InstanceOf(Equipable)
		if eqScript.SecondaryAction then
			successfullyUsed = eqScript:SecondaryAction(args)
		end
	end
	
	if not successfullyUsed and isEquipable then
		local armsEq = self.m_inventoryContainers[SurvivalInventoryManager.Containers.eGearSlots]:GetItemAt(CharacterGear.ESlotsLUT["Arms"])
		
		if armsEq and armsEq.m_item and armsEq.m_item:NKGetInstance().SecondaryAction then
			successfullyUsed = armsEq.m_item:NKGetInstance():SecondaryAction(args)
		end
	end
	
	-- If the object couldn't be used, attempt to either interact with the 
	-- target (if any), or place the held item.
	if not successfullyUsed then
		local shouldPlace = true
		if args.targetObj then
			-- Grab the script being interacted with
			local targetScript = args.targetObj:NKGetInstance()

			-- If the script has Interact defined, setup to call it.
			if targetScript.Interact then
				-- If there is an equipped item, pack it into args.
				if self.m_equippedItem then
					-- Target exists, interact.
					args.heldItem = self.m_equippedItem:NKGetInstance()
				end

				-- Call Interact with args.
				shouldPlace = not targetScript:Interact(args)
			end
		end
		
		if shouldPlace then
			-- Not working
			self:RaiseServerEvent("ServerEvent_PlayTorsoAnimOnce", { animName = "Place", TimeIN = self.DefaultAnimationBlendTime, TimeOUT = self.DefaultAnimationBlendTime, loop = false, restart = true })
			
			-- No target, place item.
			self:TryPlaceHandItem(args.positionW, args.direction, 1)
		end
	end
end

-------------------------------------------------------------------------------
-- Returns true if this player is ready to swing his weapon or hand (i.e. he has something to swing and is not already doing so).
function BasePlayer:CanSwing( )
	-- Is another swing in progress?
	if self.m_swingTimer > 0 then
		return false
	end
	-- We can swing.
	return true
end

-------------------------------------------------------------------------------
-- Plays a swing animation and starts swing audio
function BasePlayer:SwingEquippedItem( )
	
	if self:InDefaultStance() and not self:IsTransitioning() then


		if self.m_equippedItem and self.m_equippedItem:NKGetInstance():InstanceOf(Equipable) then

			local swingTransitionName = self.m_equippedItem:NKGetInstance():GetSwingTransition()

			if not swingTransitionName then
				-- Get the swing animation from the weapon.
				local animationName = self.m_equippedItem:NKGetInstance():GetRandSwingAnimationName()
				if animationName then
					--self:PlayTorsoAnimationOneShot(animName, self.Def)
					self:RaiseServerEvent("ServerEvent_PlayTorsoAnimOnce", { animName = animationName, TimeIN = self.DefaultAnimationBlendTime, TimeOUT = self.DefaultAnimationBlendTime, loop = false, restart = true })
					
					-- Play the swing noise.
					self:NKGetSound():NKPlayLocalSound("WeaponSwing", false)
					
					drainStamina = true
				end
			else
				self:TransitionStance(BasePlayer.EStanceTransitions.LookupByName[swingTransitionName])
			end
		end
		
	elseif self.m_stance == BasePlayer.EStance.eHolding then
		if self.m_equippedItem and self.m_equippedItem:NKGetInstance():InstanceOf(Throwable) then
			self:TransitionStance(BasePlayer.EStanceTransitions.eThrow)
		end
	elseif self.m_stance == BasePlayer.EStance.eHoldingPotion then
		if self.m_equippedItem and self.m_equippedItem:NKGetInstance():InstanceOf(ThrowablePotion) then
			self:TransitionStance(BasePlayer.EStanceTransitions.eThrow)
		end
	elseif self:InSlingshotHoldingStance( ) then
		if self.m_equippedItem and self.m_equippedItem:NKGetInstance():InstanceOf(RangedWeapon) then
			self.m_equippedItem:NKGetInstance():Shoot(self)
		end
	elseif self:InCastingStance( ) then
		local handsEq = self.m_inventoryContainers[SurvivalInventoryManager.Containers.eGearSlots]:GetItemAt(CharacterGear.ESlotsLUT["Hands"]) -- "Hands"
		
		if not self.m_equippedItem and handsEq and handsEq.m_item and handsEq.m_item:NKGetInstance():InstanceOf(Gauntlet) then
			handsEq.m_item:NKGetInstance():Shoot(self)
		else
			self:ResetStance()
		end
	end
end

-------------------------------------------------------------------------------
function BasePlayer:ServerEvent_ToggleHoldStance( args )
	if not self.m_equippedItem then
		local handsEq = self.m_inventoryContainers[SurvivalInventoryManager.Containers.eGearSlots]:GetItemAt(CharacterGear.ESlotsLUT["Hands"]) -- "Hands"
		
		if handsEq and handsEq.m_item and handsEq.m_item:NKGetInstance():InstanceOf(Gauntlet) then
			if self:InDefaultStance() then
				handsEq.m_item:NKGetInstance():RaiseClientEvent("ClientEvent_Aim", {player = self.object})
				--handsEq.m_item:NKGetInstance():Aim(self)
				--self.m_stance = BasePlayer.EStance.eHolding
			else 
				self:TransitionStance(BasePlayer.EStanceTransitions.eCancel)
				-- Cancel casting stance
				if self:InCastingStance() then
					handsEq.m_item:NKGetInstance():RaiseClientEvent("ClientEvent_CancelCasting", {}, { self.m_connection })
				end	
				--self.m_stance = BasePlayer.EStance.eDefault
			end	
		elseif self:InDefaultStance() then
			self:TransitionStance(BasePlayer.EStanceTransitions.eCancel)
		end
	end
end
-------------------------------------------------------------------------------
function BasePlayer:ServerEvent_Cast( args )
	if not self.m_equippedItem and self:InCastingStance( ) then
		local handsEq = self.m_inventoryContainers[SurvivalInventoryManager.Containers.eGearSlots]:GetItemAt(CharacterGear.ESlotsLUT["Hands"]) -- "Hands"
		
		if handsEq and handsEq.m_item and handsEq.m_item:NKGetInstance():InstanceOf(Gauntlet) then
			handsEq.m_item:NKGetInstance():RaiseClientEvent("ClientEvent_Shoot", {player = self.object})
			--handsEq.m_item:NKGetInstance():Shoot(self)
		else
			self:ResetStance()
		end
	else
		self:ResetStance()
	end
end

-------------------------------------------------------------------------------
function BasePlayer:SharedEvent_TransitionStance( args )
	self:TransitionStance(BasePlayer.EStanceTransitions.Lookup[args.transitionID])
end
	
-------------------------------------------------------------------------------
function BasePlayer:SharedEvent_TransitionShield( args )
	self:TransitionShield(Shield.EStanceTransitions.Lookup[args.transitionID], Shield.EStance.Lookup[args.targetStanceID])
end

-------------------------------------------------------------------------------
function BasePlayer:ServerEvent_PlayTorsoAnimOnce( args )

	if Eternus.IsServer then
		self:RaiseClientEvent("ClientEvent_PlayTorsoAnimOnce", args)
	end
end

-------------------------------------------------------------------------------
function BasePlayer:ClientEvent_PlayTorsoAnimOnce( args )

	if Eternus.IsServer and not Eternus.IsClient then
		return
	end

	if args.animName then
		self:PlayTorsoAnimationOneShot(args.animName, args.TimeIN, args.TimeOUT, args.loop, args.restart)
		if self.m_torsoAnimationSlot then 
			-- Set the swing timer so that it prevents other swings for the duration of this animation.
			local currentlyPlaying = self.m_torsoAnimationSlot:GetPlayingAnimation()
			if currentlyPlaying then
				self.m_swingTimer = 0.25
				--self.m_swingTimer = currentlyPlaying:NKGetDuration()
			end
		end
	end

end

-------------------------------------------------------------------------------
function BasePlayer:GetSwingAnimation( animName )
	return BasePlayer.EPrimaryActionAnimationLookup[animName].name
end

-------------------------------------------------------------------------------
function BasePlayer:ServerEvent_SetStance( args )
	if Eternus.IsServer then
		self:RaiseClientEvent("ClientEvent_SetStance", args)
	end
end

-------------------------------------------------------------------------------
function BasePlayer:ClientEvent_SetStance( args )
	if args.stanceID then
		self:SetStance(BasePlayer.EStance.Lookup[args.stanceID])
	end
end

-- Server side handslot equipping logic.
if Eternus.IsServer then
	-------------------------------------------------------------------------------
	-- Called from the InventoryManager when an item is inserted into the hand slot.
	function BasePlayer:HandslotEquipped( item, idx )
		self:EquipItem(item.m_item)
		self:RaiseClientEvent("ClientEvent_ItemEquipped", { equippedItem = item.m_item })
	end

	-------------------------------------------------------------------------------
	-- Called from the InventoryManager when an item is removed from the hand slot.
	function BasePlayer:HandslotUnequipped( )
		self:UnequipItem()
		self:RaiseClientEvent("ClientEvent_ItemEquipped", { equippedItem = nil })
	end
end -- Eternus.IsServer

-------------------------------------------------------------------------------
-- Shared client+server logic for equipping an item.
function BasePlayer:EquipItem( object )
	self.m_equippedItem = object

	if self.m_equippedItem:NKGetEquipable() then
		local eq = self.m_equippedItem:NKGetEquipable()
		
		-- Parent the new item and attach it to the correct bone.
		self.m_equippedItem:NKSetParent(self:GetActiveModel())
		self.m_equippedItem:NKSetAttachBone("Bn_Tool01")
		
		-- Get rotation/position offset from the hand attach point if one exists.
		local offset, rotOffset = self.m_equippedItem:NKGetInstance():GetEquipOffset()
		self.m_equippedItem:NKSetPosition(offset, false)
		self.m_equippedItem:NKSetOrientation(rotOffset)
		self.m_equippedItem:NKScale(1.0, false)
		
		-- Setup the item up in the world.
		-- EquippedItemRendersLast is overridden and managed in LocalPlayer.lua
		-- in the event that the item needs to render last for first person view.
		self.m_equippedItem:NKPlaceInWorld(false, self.EquippedItemRendersLast)
		self.m_equippedItem:NKSetShouldRender(true, true)
		
		-- On the server transform serialization is disabled.
		-- This is to allow each client's animations to drive the equipped item's position.
		-- Physics is disabled regardless so as to not interfere with the item's positioning as well.
		self.m_equippedItem:NKGetPhysics():NKDisable()
		if Eternus.IsServer then
			self.m_equippedItem:NKGetNet():NKSetShouldSerializeTransform(false)
		elseif Eternus.IsClient then -- In the case of exclusive clients, interpolation is also disabled since the server is
									   -- no longer driving position.
			self.m_equippedItem:NKGetNet():NKSetBodyInterpolationMode(EternusEngine.EInterpolationMode.eNone)
		end
	end
	
	-- Give the item a chance to do stuff when equipped.
	if self.m_equippedItem:NKGetInstance().OnEquip then
		self.m_equippedItem:NKGetInstance():OnEquip(self)
	end
end

-------------------------------------------------------------------------------
-- Shared client+server logic for unequipping an item.
function BasePlayer:UnequipItem( )
	if self.m_equippedItem and self.m_equippedItem:NKGetInstance() and self.m_equippedItem:NKGetInstance().IsValid then
		-- Detach from parent and disable emitters/move out of the render last list.
		local worldPos = self.m_equippedItem:NKGetWorldPosition()
		self.m_equippedItem:NKSetParent(nil)
		self.m_equippedItem:NKSetPosition(worldPos, false)
		self.m_equippedItem:NKGetGraphics():NKSetShouldRenderLast(false)

		if self.m_equippedItem:NKGetInstance().OnUnequip then
 			self.m_equippedItem:NKGetInstance():OnUnequip(self)
 		end
		
		-- The server disables rendering for this item, but not the client.  This
		-- is because, if we did disable rendering on the client, we run into two
		-- potential outcomes.
		-- 1. Item is placed from the hand into the world.  In this case, the client
		--    never sees the remove from world call, so it never gets another place
		--    in world call when the object is placed, meaning the object is now invisible.
		-- 2. Item is placed in another inventory slot.  In this case, the item is
		--    removed from the world and stops rendering anyway.
		-- We also re-enable serialization on the offchance it is needed further, and
		-- re-enable interpolation on the client.
		if Eternus.IsServer then
			self.m_equippedItem:NKSetShouldRender(false, true)
			self.m_equippedItem:NKRemoveFromWorld(false, true)
			self.m_equippedItem:NKGetNet():NKSetShouldSerializeTransform(true)
		elseif Eternus.IsClient then
			self.m_equippedItem:NKGetNet():NKSetBodyInterpolationMode(EternusEngine.EInterpolationMode.eKinematic)
		end
	end
	
	-- Clear the pointer.
	self.m_equippedItem = nil
end

-------------------------------------------------------------------------------
-- Client event notifying players that this character has equipped/unequipped 
-- an item.
function BasePlayer:ClientEvent_ItemEquipped( args )
	if Eternus.IsServer then
		return
	end

	local obj = args.equippedItem
	
	NKPrint("ClientEvent_ItemEquipped!\n")

	if obj and obj:NKGetInstance() and obj:NKGetInstance().IsValid then
		self:EquipItem(obj)
	else
		self:UnequipItem();
	end
end

-------------------------------------------------------------------------------
-- Called by the animation system when the state of the stance state machine changes.
-- Allows us to know when transitions have fully completed.
function BasePlayer:OnStanceChanged( graph, srcState, destState )
	for i,k in pairs(BasePlayer.EStance) do
		if k.name == destState then
			-- NKPrint("Stance Changed: " .. srcState .. " -> " .. destState .. "\n")
			self.m_stance = k
		end
	end
end

-------------------------------------------------------------------------------
-- Called by the animation system when the state of the stance state machine changes.
-- Allows us to know when transitions have fully completed.
function BasePlayer:OnShieldStanceChanged( graph, srcState, destState )
	for i,k in pairs(Shield.EStance) do
		if k.name == destState then
			-- NKWarn("Shield Stance Changed: " .. srcState .. " -> " .. destState .. "\n")
			self.m_shieldStance = k
		end
	end
end

-------------------------------------------------------------------------------
-- Trigger the provided stance transition by name.
function BasePlayer:TransitionStance( stanceTransition )

	if self.m_stanceGraph == nil then
		return false
	end

	local success = self.m_stanceGraph:NKTriggerTransition(stanceTransition.name)

	if success then 
		-- NKPrint("Transitioning to '" .. stanceTransition.name .. "'...\n")
	else
		--NKPrint("Failed to transition to '" .. stanceTransition.name .. "'...\n")
		return success
	end

	self:RaiseFakeBroadcast("SharedEvent_TransitionStance", { transitionID = stanceTransition.id })

	return success
end


-------------------------------------------------------------------------------
-- Trigger the provided stance transition by name.
function BasePlayer:TransitionShield( stanceTransition, targetStance )

	if (self.m_shieldGraph:NKGetActiveTransition() ~= stanceTransition.name) then
		local success = self.m_shieldGraph:NKTriggerTransition(stanceTransition.name)

		if success then 
			--NKPrint("Transitioning to '" .. stanceTransition.name .. "'...\n")
		else
			--NKPrint("Failed to transition to '" .. stanceTransition.name .. "'...\n")
			if targetStance then
				local result = self.m_shieldGraph:NKSetStateEx(targetStance.name)

				if result == BlendByGraph.SUCCESS then
					self.m_shieldStance = targetStance
					success = true
				else
					success = false
					return success
				end
			end
		end
		self:RaiseFakeBroadcast("SharedEvent_TransitionShield", { transitionID = stanceTransition.id, targetStanceID = targetStance.id })
	end

	return success
end

-------------------------------------------------------------------------------
-- Transitions to the provided stance without any transition or blending.
-- Cancels the active transition, if any.
function BasePlayer:SetStance( stance )

	local result = self.m_stanceGraph:NKSetStateEx(stance.name)
	local success = false

	if result == BlendByGraph.SUCCESS then
		self.m_stance = stance

		-- "successful" happens when:
		--	the state requested is valid
		--	AND
		--	the graph was NOT already in that state
		success = true
	else
		-- "failed" to set state due to:
		--	requested state being invalid
		--	graph is already in that state
		success = false
	end
--[[
	if Eternus.Debugging.Logging then
		if result == BlendByGraph.SUCCESS then
			NKInfo("[BasePlayer:SetStance] Stance set to: " .. stance.name .. ".")
		elseif  result == BlendByGraph.INVALID then
			NKError("[BasePlayer:SetStance] Attempting to set invalid stance: " .. stance.name .. ".")
		elseif result == BlendByGraph.NO_CHANGE then
			NKWarn("[BasePlayer:SetStance] Attempting to set stance (" .. stance.name .. ") when already in that stance.")
		else
			NKError("[BasePlayer:SetStance] Something went wrong while attempt to set stance: " .. stance.name .. ".")
		end
	end
--]]
	return success
end

-------------------------------------------------------------------------------
-- Transitions back to the default stance playing the appropriate transition out animation.
-- This function is hooked up to animation events.
function BasePlayer:TransitionToDefault( )
	if not self.m_primaryActionEngaged then
		self:TransitionStance(BasePlayer.EStanceTransitions.eBackToDefault)
	end
end

-------------------------------------------------------------------------------
-- Returns true if this player is currently in a transition (blend or animation).
function BasePlayer:IsTransitioning( )
	if self:IsDead() then
		return false
	else
		return self.m_stanceGraph:NKIsTransitioning()
	end
end

-------------------------------------------------------------------------------
-- Returns the user provided name of the active transition or an empty string if no
-- transition is playing.
function BasePlayer:GetActiveTransition( )
	if self:IsTransitioning() then
		return self.m_stanceGraph:NKGetActiveTransition()
	end
	return ""
end

-------------------------------------------------------------------------------
function BasePlayer:Server_Pickup( args )
	
	local objCount = args.count
	local objName = args.name

	--Obj count was valid or wasn't there, have a name.
	if objCount > 0 then
		local object = Eternus.GameObjectSystem:NKCreateNetworkedGameObject(objName, true, true)

		if object then
			object:NKPlaceInWorld(false, false)
			local success = self:Pickup(object)
			if not success then
				object:NKRemoveFromWorld(true, false)
			end
		else
			NKPrint("Failed to pickup obj name " .. objName .. "\n")
		end
	end
end

-------------------------------------------------------------------------------
function BasePlayer:HasItemEquiped( )
	return self.m_equippedItem and self.m_equippedItem:NKGetInstance():InstanceOf(Equipable)
end

-------------------------------------------------------------------------------
function BasePlayer:GetHandItem( )
	return self.m_equippedItem
end

-------------------------------------------------------------------------------
function BasePlayer:ServerEvent_TryPlaceItemAt( args )
	self:TryPlaceItemAt(args.item, args.position, args.orientation)
end

-------------------------------------------------------------------------------
function BasePlayer:SetJumpFlag( flag )
	if Eternus.IsServer and flag == true and self.m_jumping == false then
		self:_ModifyStamina(self.m_staminaDrainOnJump)
	end
	
	self.m_jumping = flag
end

-------------------------------------------------------------------------------
function BasePlayer:GetMaxReachDistance( )
	return self.m_maxReachDistance
end

-------------------------------------------------------------------------------
function BasePlayer:GetMaxLookDistance( )
	return self.m_maxLookDistance
end

-------------------------------------------------------------------------------
function BasePlayer:ResetStance( )
	if not self:InDefaultStance() and self.m_stanceGraph:NKGetTransitionDestination() ~= "Default" then
		self:RaiseClientEvent("ClientEvent_SetStance", { stanceID = BasePlayer.EStance.eDefault.id })
	end
end

-------------------------------------------------------------------------------
function BasePlayer:Save( outData )
	if self:HasDied() then
		self.m_connection:NKSetLoginLocation(self.m_connection:NKGetRespawnLocation())
	else
		self.m_connection:NKSetLoginLocation(self:NKGetWorldPosition())
	end

	outData.health = self.m_health
	outData.stamina = self.m_stamina
	outData.energy = self.m_energy:GetBase()
	outData.obesity = self.m_obesity
	outData.hairIdx = self.m_hairIdx
	outData.experience = self.m_experience

	if self.m_petname ~= nil then
		outData.petname = self.m_petname	
	end
	
	if self.m_petname ~= nil then
		outData.petname = self.m_petname	
	end

	CL:SavePlayerData(self, outData)
end

-------------------------------------------------------------------------------
function BasePlayer:Restore( inData, version )
	if inData.health <= 0 then
		self:_SetHealth(self.MaxHealth)
		self:_SetStamina(self.MaxStamina)
		self:_SetEnergy(self.MaxEnergy)
	else
		self:_SetHealth(inData.health)
		self:_SetStamina(inData.stamina)
		self:_SetEnergy(inData.energy)
	end

	if inData.petname ~= nil then
		self.m_petname = inData.petname
	end

	self.m_hairIdx = inData.hairIdx or self.m_hairIdx
	self.m_obesity = inData.obesity or self.m_obesity
	self.m_experience = inData.experience or self.m_experience
	
	CL:RestorePlayerData(self, inData, version)
end

-------------------------------------------------------------------------------
function BasePlayer:ServerEvent_SetBlockBrush( args )

	if Eternus.IsServer then
		self.CurrentBlockBrush = self.BlockBrush[args.brushIdx];
	end
end

-------------------------------------------------------------------------------
function BasePlayer:GetDisplayName()
	return self.m_playerName
end

-------------------------------------------------------------------------------
function BasePlayer:ClientEvent_PlayMiningEmitter( args )
	Eternus.ParticleSystem:NKPlayWorldEmitter(args.position, args.name)
end

-------------------------------------------------------------------------------
-- THIS IS A CLIENT EVENT
-- THEN IT SHOULD BE PREFIXED WITH ClientEvent_
function BasePlayer:Play3DSound( args )
	if Eternus.IsServer and not Eternus.IsClient then
		return
	end

	-- Enter alert
	self:NKGetSound():NKPlay3DSound(args.sound, false, self.ThreeDSoundOffset, 15.0, 135.0)
end

-------------------------------------------------------------------------------
-- Callback from the SurvivalInventoryManager when a Gameobject has been placed in a gear slot.
-- slotId is a string (e.g. "Head", "Chest", etc. )
function BasePlayer:OnGearEquipped( slotId, gearGameObject, playEffect )
	if not self.m_3pobject then return end

	if not gearGameObject:InstanceOf( EquipableGear ) or not gearGameObject:AltersAppearance() then
		self.m_3pobject:ClearSlotAppearanceRules( slotId )
	else
		self.m_3pobject:SetSlotAppearanceRules( slotId, gearGameObject:GetAppearanceRules() )

		if Eternus.IsClient and playEffect then
			gearGameObject:PlayEquipEffects( self )
		end
	end
end

-------------------------------------------------------------------------------
-- Callback from the SurvivalInventoryManager when a gameobject has been removed from a gear slot
function BasePlayer:OnGearRemoved( slotId )
	if not self.m_3pobject then return end
	self.m_3pobject:ClearSlotAppearanceRules( slotId )
end

-------------------------------------------------------------------------------
function BasePlayer:PlayerEmitterAtPosition( emitterName, verticalOffset )
	verticalOffset = verticalOffset or 1.5 -- Default vertical offset for the player
	local myPos = self:NKGetWorldPosition()
	myPos = vec3.new(myPos:x(), myPos:y() + verticalOffset, myPos:z())
	Eternus.ParticleSystem:NKPlayWorldEmitter(myPos, emitterName)
end

-- Experience functions below are server side only.
if Eternus.IsServer then
	-------------------------------------------------------------------------------
	-- Helper to modify m_experience by the provided amount.
	function BasePlayer:_ModifyExperience( amount )
		self:_SetExperience( self.m_experience + amount )
	end

	-------------------------------------------------------------------------------
	-- Never set m_experience directly, always use this function. Code interested in doing stuff when experience changes
	-- should listen on the m_expChangedSignal.
	function BasePlayer:_SetExperience( value )
		self.m_experience = value
		self.m_expChangedSignal:Fire( value )
	end

	-------------------------------------------------------------------------------
	-- Public accessor to add experience to this player. This is a server side function only.
	-- In the future this will likely play an effect which may involve some net events.
	function BasePlayer:AddExperience( amount )
		self:_ModifyExperience( amount )
	end

	-------------------------------------------------------------------------------
	-- Called on the server from Bed.lua (for now) at the darkest part of slumber.
	function BasePlayer:OnSleep( bed )
		self:CommitExperience()
	end

	-------------------------------------------------------------------------------
	-- Tell clients to apply effects from the current experience amount. This is necessary because seed
	-- growth happens only when the player sleeps.
	function BasePlayer:CommitExperience()
		self:RaiseClientEvent("Client_ApplyExperienceEffects", { experience = self.m_experience })
	end
end -- Eternus.IsServer

-- Experience asthetics functions that are client side only.
if Eternus.IsClient then
	-------------------------------------------------------------------------------
	-- Client netevent handler used to trigger _ApplyExperienceEffects. 
	function BasePlayer:Client_ApplyExperienceEffects( args )
		if args.experience then
			self:_ApplyExperienceEffects( args.experience )
		end
	end

	-------------------------------------------------------------------------------
	-- Make the provided exp value 'take effect'- this happens at specific times, such as when sleeping and loading into the game.
	function BasePlayer:_ApplyExperienceEffects( amount )
		local name, growthState = nil;
		local highestExp = 0.0
		for key, state in pairs(self.GrowthState) do 
			if state.Experience <= amount and state.Experience >= highestExp then
				name = key
				growthState = state
				heighestExp = state.Experience
			end
		end

		self:_ApplyGrowthState( growthState, name )
	end

	-------------------------------------------------------------------------------
	-- Configure this player into a specific 'growth state' found in BasePlayer.GrowthState.
	function BasePlayer:_ApplyGrowthState( growthState, stateName )
		--self.m_3pobject:SetGrowthState( stateName )
		self:_UpdateGearVisuals( nil, growthState.AgeMorph, nil )
		self.m_3pobject:NKScale( growthState.SeedScale, false )
	end
end -- Eternus.IsClient

-------------------------------------------------------------------------------
-- Returns the currently equipped item in this players hand, or nil if he does not have one.
function BasePlayer:GetEquippedItem()
	if not self.m_equippedItem then
		return nil
	end
	return self.m_equippedItem:NKGetInstance() 
end

-------------------------------------------------------------------------------
--------------------------- FOR DATA METRIC SYSTEM ----------------------------
-------------------------------------------------------------------------------
function BasePlayer:OnSuccessfulCraft( craftedObj )
	self:RaiseGameAction("Craft", craftedObj)
end

-------------------------------------------------------------------------------
function BasePlayer:OnFailureCraft( failureObj )
end

-- -------------------------------------------------------------------------------
-- function BasePlayer:OnConsume( targetObject )
-- 	self:RaiseGameAction("Consume", targetObject)
-- end

-- -----------------------------------------------------------------------------
-- function BasePlayer:OnSuccessfulDestroy( targetObject )
-- 	self:RaiseGameAction("Destroy", targetObject)
-- end

-- -------------------------------------------------------------------------------
-- function BasePlayer:OnSuccessfulSkin( targetObject )	
-- 	self:RaiseGameAction("Skin", targetObject)
-- end

-- -------------------------------------------------------------------------------
-- function BasePlayer:OnSuccessfulDefeat( targetObject )
-- 	self:RaiseGameAction("Defeat", targetObject)
-- end

-- -------------------------------------------------------------------------------
-- -- Returns true if Baseplayer defeats a character (for data metric tracking) 
-- function BasePlayer:IsCharacterDefeated( targetObject )
-- 	if targetObject then
-- 		local targetObjScript = targetObject:NKGetInstance() 
-- 		if targetObjScript ~= nil then
-- 			-- Check to see if the targetObject has been defeated
-- 			if targetObjScript:GetIsCharacterDefeated() then
-- 				return true
-- 			end
-- 		end
-- 	end
-- 	return false
-- end

-- -------------------------------------------------------------------------------
-- -- Returns true if Baseplayer skins a character 
-- function BasePlayer:IsCharacterSkinned( targetObject )
-- 	if targetObject then
-- 		local targetObjScript = targetObject:NKGetInstance() 
-- 		if targetObjScript ~= nil then	
-- 			-- Check to see if the targetObject is skinned
-- 			if targetObjScript:GetIsCharacterSkinned() then
-- 				return true
-- 			end
-- 		end
-- 	end
-- 	return false
-- end

-- -------------------------------------------------------------------------------
-- -- Returns true if Baseplayer destroys an object  
-- function BasePlayer:IsObjectDestroyed( targetObject )
-- 	if targetObject then
-- 		local targetObjScript = targetObject:NKGetInstance() 
-- 		if targetObjScript ~= nil then
-- 			-- Check to see if the targetObject has been destroyed
-- 			if targetObjScript:GetIsObjectDestroyed() then
-- 				return true
-- 			end
-- 		end
-- 	end
-- 	return false
-- end



