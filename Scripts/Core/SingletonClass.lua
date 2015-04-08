if SingletonClass == nil then
	SingletonClass 				= {}
	SingletonClass.__index		= SingletonClass
	SingletonClass.__mixins		= { }
end

local RegisteredClasses = { }

function SingletonClass.__index( t, k )
	local classValue = rawget(SingletonClass, k)
	if classValue ~= nil then
		return classValue
	end
	if k ~= "__indexdelegate" and t.__indexdelegate then
		return t.__indexdelegate(k)
	end
	return nil
end

function SingletonClass.Subclass( className, delegate, parentTable )
	if not parentTable then parentTable = SingletonClass end

	local newClass  				= RegisteredClasses[className] and RegisteredClasses[className]  or { }
	newClass.__classname 			= className
	newClass.__super				= parentTable
	newClass.__indexdelegate 		= delegate
	newClass.__index 				= newClass
	newClass.__mixins				= { }

	-- Setup the inheritance chain.
	if parentTable ~= nil then
		setmetatable( newClass, parentTable )
	else
		setmetatable( newClass, SingletonClass )
	end

	function newClass.new( ... )
		if not newClass.instance then 
			newClass.instance = { __class = newClass, __mixins = { } }
			setmetatable( newClass.instance, newClass )
			newClass.instance:__Constructor()
		end
		return newClass.instance
	end

	function newClass.Subclass( className, delegate )
		return SingletonClass.Subclass(className, delegate, newClass)
	end

	function newClass.__Constructor(...)
		newClass.__super.__Constructor(...)

		if type(rawget(newClass, "Constructor")) == "function" then
			newClass.Constructor(...)
		end

		for mixin, val in pairs(rawget(newClass, "__mixins")) do
			if type(rawget(mixin, "__Constructor")) == "function" then
				mixin.__Constructor(...)
			end
		end
	end

	function newClass.Mixin( self, mixin, args )
		assert(type(mixin) == "table")
		assert(mixin.Mix)
		if not self.__mixins[mixin] then
			mixin:Mix(self)

			-- call the Constructor hook to allow custom logic by the mixin.
			if mixin.__Constructor then
				mixin.__Constructor(self, args)
			end
		end
	end

	function newClass.StaticMixin( mixin )
		assert(type(mixin) == "table")
		assert(mixin.Mix)

		mixin:Mix(newClass)
	end

	RegisteredClasses[className] = newClass

	return newClass
end

-- Empty default constructor
function SingletonClass:__Constructor()
end

-- Empty default constructor
function SingletonClass:Constructor()
end

function SingletonClass:InstanceOf( class )
	local c = self
	while c and type(c) == "table" do
		--NKError(class.__classname .. "    " .. c.__classname)
		if c == class or c.__mixins[class] then
			return true
		end
		c = getmetatable(c)
	end
	return false
end

function SingletonClass:ToString()
	return self.__classname .. " instance"
end

function SingletonClass:PrintState()
	NKPrint("[" .. self.__classname .. "]: " .. EternusEngine.Debugging.Inspect(self))
end

function SingletonClass:ClassName()
	return self.__classname
end

-- For require
return SingletonClass