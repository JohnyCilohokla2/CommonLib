local quat = {w = 0, x = 0, y = 0, z = 0}
quat.__index = quat

function quat.new(w, x, y, z)
	return setmetatable({
	w = w or 0,
	x = x or 0,
	y = y or 0,
	z = z or 0,
	},quat)
end

function quat.__tostring(v)
	return ('quat: w: %.5f x: %.5f y:%.5f z: %.5f'):format(v.w, v.x, v.y, v.z)
end

return setmetatable(quat,
	{__call= function(self,...)
		return quat:new(...)
	end
})