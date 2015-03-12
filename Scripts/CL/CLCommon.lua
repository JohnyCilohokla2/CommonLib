function strStartsWith(String,startString)
   return #String>=#startString and (string.sub(String,1,string.len(startString))==startString)
end

function strEndsWith(String,endString)
   return #String>=#endString and (endString=='' or string.sub(String,-string.len(endString))==endString)
end

function CL.println(...)
  for _,v in ipairs(arg) do
   NKPrint("[CL] " .. v .. " ")
  end
   NKPrint("\n")
end

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

CL.IDS = require("Scripts.CL.IDS.IDS")
CL.inspect = require("Scripts.Utils.inspect")