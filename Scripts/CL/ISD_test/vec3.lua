local vec3 = {x = 0, y = 0, z = 0}
vec3.__index = vec3

-- Inits a new vector
function vec3.new(x, y, z)
	return setmetatable({
	x = x or 0,
	y = y or 0,
	z = z or 0,
	},vec3)
end

-- Tostrings vector
function vec3.__tostring(v)
	return ('vec3: x: %.5f y:%.5f z: %.5f'):format(v.x, v.y, v.z)
end

return setmetatable(vec3,
	{__call= function(self,...)
		return vec3:new(...)
	end
})