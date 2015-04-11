include("Scripts/CL/Mod.lua")

if (CL.mods == nil) then
	CL.println("Common Lib - Initizing Mods")
	CL.mods = {}

	local file = io.open("Config/mods.txt", "r")
	if file then
		
		file = io.open("Config/mods.txt", "r")
		for line in file:lines() do
			line = line:gsub("%s+", "")
			if (strStartsWith(line,"\"") and strEndsWith(line,"\"")) then
				--table.insert(CL.mods,string.sub(line,2,-2))
				local modPath = string.sub(line,2,-2)
				CL.println("Loading "..modPath)
				
				local manifestFile=io.open(modPath.."/Manifest.txt","r")
				if manifestFile~=nil then 
					local ScriptFile = nil
					local ScriptClass = nil
					for manifestLine in manifestFile:lines() do
						manifestLine = manifestLine:gsub("%s+", "")
						if (strStartsWith(manifestLine,"ScriptFile=\"") and strEndsWith(manifestLine,"\"")) then
							ScriptFile = string.sub(manifestLine, 13, -2)
						elseif (strStartsWith(manifestLine,"ScriptClass=\"") and strEndsWith(manifestLine,"\"")) then
							ScriptClass = string.sub(manifestLine, 14, -2)
						end
					end
					local ScriptMod = nil
					if (ScriptFile~=nil) and (ScriptClass~=nil) then
						include(ScriptFile)
						if _G[ScriptClass] and _G[ScriptClass].new then
							ScriptMod = _G[ScriptClass].new()
							ScriptMod:setup(modPath)
						else
							NKError("Couldn't initialize "..tostring(ScriptClass).." from "..(modPath..ScriptFile).."!")
						end
					end
					table.insert(CL.mods, {instance = ScriptMod, fileName = ScriptFile, className = ScriptClass, path = modPath})
				end
			end
		end
		io.close(file)
	else
		NKError("Couldn't load Config/mods.txt")
	end
end

CL:initializeHooks()