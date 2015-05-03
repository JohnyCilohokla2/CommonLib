include( "Scripts/Core/Class.lua" )

function __nativedelegate( nativeClass, attachKey )
	local cache = {}
	local function internal( k )
		local delegateFunction = nativeClass[k]
		if delegateFunction ~= nil then
			local memoized = cache[k]
			if memoized == nil then 
				memoized = function(self, ...)
					-- If you get an error here, it means you tried to call a non existant native function.
					return nativeClass[k](self[attachKey], select(1, ...))
				end
				cache[k] = memoized
			end
			return memoized
		end
	end
	return internal
end

-- These must be below the __nativedelegate helper.
include("Scripts/Core/GameObjectClass.lua")

if GameStateClass == nil then
	GameStateClass = Class.Subclass("GameStateClass")
end

if BiomeClass == nil then
	BiomeClass = Class.Subclass("BiomeClass")
end

if ModScriptClass == nil then
	ModScriptClass = require("Scripts.Core.SingletonClass").Subclass("ModScriptClass")
	ModScriptClass.StaticMixin(require("Scripts.CL.Mod"))
end

include("Scripts/CL/CL.lua")

function BiomeClass:GetRoot()
	local heightRoot, matRoot = self:BuildTree()

	if not matRoot then
		matRoot = heightRoot
	end

	local biome = BiomeModule.new()
	biome:NKSetName(self.__classname)
	
	CL:ModifyBiomeData(self.__classname, self)

	if self.Objects then
		biome:NKSetObjects(self.Objects)
	end

	if self.Clusters then
		biome:NKSetClusters(self.Clusters)
	end
	
	if self.Lighting then
		biome:NKSetLighting(self.Lighting)
	end

 	biome:NKSetSourceModuleHeight(0, heightRoot)
	biome:NKSetSourceModuleMaterial(0, matRoot)
	return biome
end

-------------------------------------------------------------------------------
function BiomeClass:ConstructTree( tree )
	local biome = self:GetRoot()

	-- Set it as the root.
	tree:NKSetHeightRoot(biome)
	tree:NKSetMaterialRoot(biome)
end

function BiomeClass:GetHeightRoot()
	return self.m_heightRoot
end

function BiomeClass:GetMaterialRoot()
	return self.m_materialRoot
end

function BiomeClass:Simplex( scale, numOctaves )
	local m = SimplexModule.new()
	m:NKSetScale(scale)
	m:NKSetNumOctaves(numOctaves)
	return m
end

function BiomeClass:Constant( value )
 	local m = ConstantModule.new()
 	m:NKSetValue(value)
	return m
end

function BiomeClass:Add( node1, node2 )
 	local m = AddModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetSourceModuleHeight(1, node2)
	return m
end

function BiomeClass:Average( node1, node2 )
 	local m = AverageModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetSourceModuleHeight(1, node2)
	return m
end

function BiomeClass:Multiply( node1, node2 )
 	local m = MultiplyModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetSourceModuleHeight(1, node2)
	return m
end

function BiomeClass:Power( node1, node2 )
 	local m = PowerModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetSourceModuleHeight(1, node2)
	return m
end

function BiomeClass:Clamp( node1, Upper, Lower )
 	local m = ClampModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetUpperBound(Upper)
	m:NKSetLowerBound(Lower)
	return m
end

function BiomeClass:Abs( node1 )
 	local m = AbsModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
	return m
end

function BiomeClass:Curve( node1 )
 	local m = CurveModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
	return m
end

function BiomeClass:Invert( node1 )
 	local m = InvertModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
	return m
end

function BiomeClass:Normalize( node1 )
 	local m = NormalizeModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
	return m
end

function BiomeClass:Max( node1, node2 )
 	local m = MaxModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetSourceModuleHeight(1, node2)
	return m
end

function BiomeClass:Max( node1, node2, matNode1, matNode2 )
 	local m = MaxModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetSourceModuleHeight(1, node2)
	m:NKSetSourceModuleMaterial(0, matNode1)
	m:NKSetSourceModuleMaterial(1, matNode2)
	return m
end

function BiomeClass:Min( node1, node2 )
 	local m = MinModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetSourceModuleHeight(1, node2)
	return m
end

function BiomeClass:Min( node1, node2, matNode1, matNode2 )
 	local m = MinModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetSourceModuleHeight(1, node2)
	m:NKSetSourceModuleMaterial(0, matNode1)
	m:NKSetSourceModuleMaterial(1, matNode2)
	return m
end

function BiomeClass:Terrace( node1 )
 	local m = TerraceModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
	return m
end

function BiomeClass:Nearest( node1 )
 	local m = NearestModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
	return m
end

function BiomeClass:Blend( node1, node2, weight, matNode1, matNode2 )
 	local m = BlendModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetSourceModuleHeight(1, node2)
 	m:NKSetSourceModuleHeight(2, weight)
	m:NKSetSourceModuleMaterial(0, matNode1)
	m:NKSetSourceModuleMaterial(1, matNode2)
 	return m
end

function BiomeClass:Select( node1, node2, weight, matNode1, matNode2 )
 	local m = SelectModule.new()
 	m:NKSetSourceModuleHeight(0, node1)
 	m:NKSetSourceModuleHeight(1, node2)
 	m:NKSetSourceModuleHeight(2, weight)
	m:NKSetSourceModuleMaterial(0, matNode1)
	m:NKSetSourceModuleMaterial(1, matNode2)
 	return m
end

function BiomeClass:Material( materialName )
 	local m = MaterialModule.new()
 	m:NKSetMaterialName(materialName)
	return m
end

function BiomeClass:Switch( node1, node2, weight, matNode1, matNode2 )
 	local m = SwitchModule.new()
 	m:NKSetThreshold(0.0)
 	m:NKSetSourceModuleHeight(0, node1)
	m:NKSetSourceModuleHeight(1, node2)
 	m:NKSetSourceWeight(weight)
	m:NKSetSourceModuleMaterial(0, matNode1)
	m:NKSetSourceModuleMaterial(1, matNode2)
 	return m
end

function BiomeClass:SwitchHeight( node1, node2, weight)
 	local m = SwitchModule.new()
 	m:NKSetThreshold(0.0)
 	m:NKSetSourceModuleHeight(0, node1)
	m:NKSetSourceModuleHeight(1, node2)
 	m:NKSetSourceWeight(weight)
 	return m
end

function BiomeClass:SwitchMaterial( matnode1, matmode2, weight )
	 local m = SwitchModule.new()
 	m:NKSetThreshold(0.0)
 	m:NKSetSourceModuleMaterial(0, matnode1)
	m:NKSetSourceModuleMaterial(1, matmode2)
 	m:NKSetSourceWeight(weight)
 	return m
end