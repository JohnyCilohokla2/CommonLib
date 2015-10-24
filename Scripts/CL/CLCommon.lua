function strStartsWith(String,startString)
   return #String>=#startString and (string.sub(String,1,string.len(startString))==startString)
end

function strEndsWith(String,endString)
   return #String>=#endString and (endString=='' or string.sub(String,-string.len(endString))==endString)
end

function CL.println(...)
	local out = ""
	out = out .. ("[CL] ")
	for _,v in ipairs(arg) do
		out = out .. (v .. " ")
	end
	NKPrint(out)
end

CL.out = CL.println

function CL.round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function CL.compareVec3(vector1, vector2, delta)
	delta = delta or 0.00001
	local diff = (vector1-vector2):NKLength()
	if (diff<delta) then
		return true
	end
	return false
end

CL.vec3Meta = getmetatable(vec3(1))

function CL.isVec3(value)
	if not value then
		return false
	end
	return (getmetatable(value)==CL.vec3Meta)
end

CL.quatMeta = getmetatable(quat(1,0,0,0))

function CL.isQuat(value)
	if not value then
		return false
	end
	return (getmetatable(value)==CL.quatMeta)
end

CL.inspect = require("Scripts.Utils.inspect")

JSON = require("Scripts.Libs.JSON")
