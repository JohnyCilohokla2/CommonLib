if CLMod == nil then
	CLMod = EternusEngine.Class.Subclass("CLMod")
	CLMod.m_name = nil
	CLMod.m_hookList = {}
	CLMod.m_path = nil
	CLMod.m_handler = nil
end

function CLMod:Constructor( args, path )
	self.m_path = path
	self:setup(args, path)
end

	
function CLMod:setup( args, path )
end

function CLMod:initialize()
end

function CLMod:connectHandler(handler)
	self.m_handler = handler
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