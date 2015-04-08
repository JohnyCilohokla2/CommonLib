if CLMod == nil then
	CLMod = EternusEngine.Mixin.Subclass("CLMod")
end

function CLMod:setup( path )
	CL.println("CLMod:setup" .. path)
	self.m_hookList = {}
	self.m_path = path
end

function CLMod:loadHooks()
	CL.println("CLMod loadHooks")
	for hookID, hook in pairs(self.m_hookList) do
		local hookFile=io.open(self.m_path.."/Scripts/Hooks/"..hook,"r")
		if hookFile~=nil then 
			io.close(hookFile)
			local hooks = assert(loadfile(self.m_path.."/Scripts/Hooks/"..hook))
			hooks()
		else
			NKError("Couldn't load hook file "..self.m_path.."/Scripts/Hooks/"..hook)
		end
	end
end

return CLMod