local dkjson = require("Scripts.Libs.dkjson")

if JSON == nil then
	JSON = Class.Subclass("JSON")
end

JSON.parsers = {}
JSON.parser = nil

-- returns string, status(true/false), err
function JSON.jsonEncode(object)
	return dkjson.encode (object, { indent = true })
end

-- returns obj, pos, err
function JSON.jsonDecode(str)
	return dkjson.decode (str, 1, nil)
end

function JSON.parseFile(fileName)
	file = io.open(fileName, "r")
	io.input(file)
	local str = io.read("*all")
	io.close(file)

	local obj, pos, err = JSON.jsonDecode(str)
	if err then
		NKPrint("[JSON] Error: " .. err)
		return nil, err
	else
		obj = JSON.parser(obj)
		return obj, nil
	end

end

JSON.parser = function(data)
	if type(data) ~= "table" then
		return data
	elseif ((data["$"] ~= nil) and (JSON.parsers[data["$"]]~=nil)) then
		return JSON.parsers[data["$"]](data)
	else
		for key,value in pairs(data) do
			data[key] = JSON.parser(value)
		end
		return data
	end

end

JSON.parsers.IGC = function (input)
	local out = {};
	out.name = input.name;
	out.targets = {};
	for key,value in pairs(input.targets) do
		out.targets[key] = JSON.parser(value)
	end
	return out
end

JSON.parsers.IGCTarget = function (input)
	local out = {};
	out.name = input.name;
	out.locations = {};
	for key,value in pairs(input.locations) do
		out.locations[key] = JSON.parser(value)
	end
	out.ingredients = {};
	for key,value in pairs(input.ingredients) do
		out.ingredients[key] = value
	end
	return out
end

JSON.parsers.IGCLocation = function (input)
	local out = {};
	if (input.position ~=nil) then
		out.position = JSON.parser(input.position)
	end
	if (input.rotation ~=nil) then
		out.rotation = JSON.parser(input.rotation)
	end
	return out
end

JSON.parsers.Vec3D = function (input)
	return vec3.new(input.x,input.y,input.z)
end

JSON.parsers.Quat = function (input)
	return quat.new(input.w,input.x,input.y,input.z)
end

return JSON