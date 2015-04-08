include( "Scripts/Core/Class.lua" )
include( "Scripts/Core/Mixin.lua" )
if EternusEngine == nil then
	EternusEngine = {}
	EternusEngine.Class  = Class
	EternusEngine.Mixin  = Mixin
end
include( "Scripts/Core/NativeClasses.lua" )
include( "Scripts/Core/NKMath.lua")
include( "Scripts/Core/NKUtils.lua")
include( "Scripts/Core/NKTerrain.lua")

if EternusEngine.Initilized == nil then
	EternusEngine.GameObjectClass = GameObjectClass
	EternusEngine.GameStateClass  = GameStateClass
	EternusEngine.RecipeClass = RecipeClass
	EternusEngine.BiomeClass  = BiomeClass
	EternusEngine.ModScriptClass  = ModScriptClass
	EternusEngine.Math = NKMath
	EternusEngine.Terrain = NKTerrain
	EternusEngine.Debugging = {}
	EternusEngine.Debugging.Inspect = include("Scripts/Utils/inspect.lua")
	EternusEngine.Debugging.Breakpoint = include("Scripts/Debugger.lua")
	include( "Scripts/Buffs/BuffManager.lua")
	EternusEngine.BuffManager = BuffManager.new({})
	EternusEngine.Initilized = true
	include( "Scripts/Projectiles/ProjectileManager.lua")
	EternusEngine.ProjectileManager = ProjectileManager.new({})
	EternusEngine.DamageManager = include("Scripts/Core/DamageManager.lua")
	EternusEngine.Statistics = include("Scripts/Core/NKStatistics.lua")
end

-------------------------------------------------------------------------------
-- CEGUI Systems
--EternusEngine.UI.System 		- CEGUI::System
--EternusEngine.UI.Fonts 		- CEGUI::FontManager
--EternusEngine.UI.Schemes 		- CEGUI::SchemeManager
--EternusEngine.UI.Windows 		- CEGUI::WindowsManager
--EternusEngine.UI.Animations 	- CEGUI::AnimationManager
--EternusEngine.UI.Logger 		- CEGUI::DefaultLogger
--EternusEngine.UI.GuiCtx 		- CEGUI::GUIContext (Render surface / input)

-- This covers the initial startup of the engine, since systems
--	are only partially online when the gui is ready to link with Eternus.
if EternusEngine.UI == nil and CEGUI then
	EternusEngine.UI = {}
	EternusEngine.UI.System = CEGUI.System:getSingleton()
	EternusEngine.UI.Fonts = CEGUI.FontManager:getSingleton()
	EternusEngine.UI.Schemes = CEGUI.SchemeManager:getSingleton()
	EternusEngine.UI.Windows = CEGUI.WindowManager:getSingleton()
	EternusEngine.UI.Animations = CEGUI.AnimationManager:getSingleton()
	EternusEngine.UI.Logger = CEGUI.Logger:getSingleton()
	EternusEngine.UI.GuiCtx = __CEGUI_GUIContext_Inst
	__CEGUI_GUIContext_Inst:setDefaultFont("DevinneSwash-10")


	EternusEngine.UI.Root = EternusEngine.UI.Windows:createWindow("DefaultWindow", "applicationRoot")
	EternusEngine.UI.Root:setMouseInputPropagationEnabled(true)

	EternusEngine.UI.Layers = {}
	EternusEngine.UI.Layers.Gameplay = EternusEngine.UI.Windows:createWindow("DefaultWindow", "gameplayRoot")
	EternusEngine.UI.Layers.Gameplay:setMouseInputPropagationEnabled(true)
	EternusEngine.UI.Root:addChild(EternusEngine.UI.Layers.Gameplay)
	EternusEngine.UI.GuiCtx:setRootWindow(EternusEngine.UI.Root)

end

--[[																	]]--
--[[	Need to find a good place to put everything below this point.	]]--
--[[																	]]--
KEY_FLOOD = 0.0000
KEY_ONCE = 99999999.0
--VK_CONTROL =  17
--VK_SHIFT =  16

VK_SHIFT = EternusKeycodes.LSHIFT
VK_CONTROL = EternusKeycodes.LCTRL

-- This must match EquipableComponent::EHandleType enum found in EquipableComponent.h
EternusEngine.EHandleType = 
{
	eHandleOne 		= 0,
	eHandleTwo 		= 1,
	eHandleTwoLeft 	= 2,
	eHandleMisc		= 3
}

--Needs to match ESpecialType in HavokTypes.h
EternusEngine.EPhysicsTraceType =
{
	eUnknown 	= -1,
	eAny 		= 0,
	eTerrain 	= 1,
	eVoxel 		= 1,
	eRigidBody 	= 2,
	eObject 	= 2,
	eController = 3,

}

-- All of the available run-time built primitives
--	Currently only for physics, not renderable.
EternusEngine.EPrimitiveTypes =
{
	eSphere		= 0,
	eCube		= 1,
	eCylinder 	= 2,
	eCone 		= 3
}

EternusEngine.EPrimitiveTypeStrings = 
{
	Sphere 		= EternusEngine.EPrimitiveTypes.eSphere,
	Cube 		= EternusEngine.EPrimitiveTypes.eCube,
	Cylinder 	= EternusEngine.EPrimitiveTypes.eCylinder,
	Cone 		= EternusEngine.EPrimitiveTypes.eCone
}


EternusEngine.EInterpolationMode = 
{
	eNone 		= 0,
	eLinear 	= 1,
	eKinematic 	= 2,
	ePlayer		= 3,
}

EternusEngine.EBuffConflict =
{
	eNone 	  = 0,
	eConflict = 1,
	eMatch 	  = 2,

}

local FailLevelDefinitions =
{
	[1] =
	{
		Text = "Error",
		id = 1,
	},
	[2] =
	{
		Text = "Warning",
		id = 2,
	},
}

EternusEngine.EFailLevel =
{
	eError = 1,
	eWarning = 2,

	AsText = function(id)
		if id < 1 or id > table.getn(FailLevelDefinitions) then
			return "Unknown Error"
		else 
			return FailLevelDefinitions[id].Text
		end
	end,
}

local FailReasonDefinitions =
{
	[1] =
	{
		Text = "Invalid",
		id = 1,
	},
	[2] =
	{
		Text = "Do not have permission",
		id = 2,
	},
	[3] = 
	{
		Text = "No item Equiped",
		id = 3,
	},
	[4] =
	{
		Text = "On Cooldown",
		id = 4,
	}
}

EternusEngine.EFailReason =
{
	eInvalid = 1,
	ePermission = 2,
	eNoItemEquip = 3,
	eOnCooldown = 4,

	AsText = function(id)
		if id < 1 or id > table.getn(FailReasonDefinitions) then
			return "Unknown Reason"
		else 
			return FailReasonDefinitions[id].Text
		end
	end,
}

-- SHOULD BE USING ETERNUS!!!
if Eternus.Debugging == nil then
	Eternus.Debugging = {}
end
Eternus.MAX_RAYCAST_DISTANCE = 10000.0
Eternus.Debugging.Enabled = false
Eternus.Debugging.Logging = true
Eternus.Debugging.Generation = false
Eternus.Debugging.GenerationDistance = 6

return EternusEngine