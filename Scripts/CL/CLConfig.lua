CLConfig = Class.Subclass("CLConfig")

function CLConfig:Constructor(mod, filename)
	self.m_filename = mod:NKGetPath().."/"..filename
	self.m_data = {}
end

function CLConfig:Load()
	local file = io.open(self.m_filename, "r")
	if file then
		io.input(file)
		local str = io.read("*all")
		io.close(file)
		
		local obj, pos, err = JSON.jsonDecode(str)
		if err then
			NKWarn("[CLConfig] Error loading file: " .. self.m_filename)
			NKWarn("[CLConfig] Error: " .. err)
			NKPrint("[CLConfig] Error in: " .. str)
			return false, pos, err
		else
			obj = JSON.decoder(obj)
			self.m_data = obj
			return true
		end
	end
	return false
end

function CLConfig:Save()
	local file = assert(io.open(self.m_filename, "w"))
	if file then
		local str, pos, err = JSON.encode(self.m_data)
		if err then
			NKWarn("[CLConfig] Error saving to file: " .. self.m_filename)
			NKWarn("[CLConfig] Error: " .. err)
			NKPrint("[CLConfig] Error in: " .. pos)
			file:close()
			return false, pos, err
		else
			file:write(str)
			file:close()
			return true
		end
	end
end

return CLConfig