local json = require ("dkjson")
local inspect = require ("inspect")

local vec3 = require ("vec3")
local quat = require ("quat")

local handlers = {}
local isd_parse = nil

handlers["IGC"] = function (input)
	local out = {};
	out.targets = {};
	for key,value in pairs(input.targets) do
		out.targets[key] = isd_parse(value)
	end
	return out
end

handlers["IGCTarget"] = function (input)
	local out = {};
	out.locations = {};
	for key,value in pairs(input.locations) do
		out.locations[key] = isd_parse(value)
	end
	out.ingredients = {};
	for key,value in pairs(input.ingredients) do
		out.ingredients[key] = value
	end
	out.name = input.name;
	return out
end

handlers["IGCLocation"] = function (input)
	local out = {};
	if (input.position ~=nil) then
		out.position = isd_parse(input.position)
	end
	if (input.rotation ~=nil) then
		out.rotation = isd_parse(input.rotation)
	end
	return out
end

handlers["Vec3D"] = function (input)
	return vec3.new(input.x,input.y,input.z)
end

handlers["Quat"] = function (input)
	return quat.new(input.w,input.x,input.y,input.z)
end

isd_parse = function(data)

	if ((data["$"] ~= nil) and (handlers[data["$"]]~=nil)) then
		return handlers[data["$"]](data)
	else
		for key,value in pairs(data) do
			CL.println (key, value)
		end
		return data
	end

end


function isd()
	file = io.open("ConveyorBeltFrame.isd", "r")
	io.input(file)
	local str = io.read("*all")
	io.close(file)

	local obj, pos, err = json.decode (str, 1, nil)
	if err then
		CL.println ("Error:", err)
		return nil, err
	else
		obj = isd_parse(obj)
		return obj, nil
	end

end

print (inspect.inspect(isd()))
