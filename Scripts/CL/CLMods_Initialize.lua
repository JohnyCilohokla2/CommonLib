
if (CL.mods == nil) then
	CL.println("Common Lib - Initizing Mods")
	CL.mods = {}
	CL.tugMods = {}

	local file = io.open("Config/mods.txt", "r")
	if file then
		for line in file:lines() do
			line = line:gsub("%s+", "")
			if (strStartsWith(line,"\"") and strEndsWith(line,"\"")) then
				--table.insert(CL.mods,string.sub(line,2,-2))
				local modPath = string.sub(line,2,-2)
				CL.println("Loading "..modPath)

				local modFile=io.open(modPath.."/Scripts/CLMod.lua","r")
				if modFile~=nil then 
					io.close(modFile)
					local modClass = assert(loadfile(modPath.."/Scripts/CLMod.lua"))
					local mod = modClass():new(modPath)
					CL.mods[mod.m_name] = mod
				end
			end
		end
		
		file = io.open("Config/mods.txt", "r")
		for line in file:lines() do
			line = line:gsub("%s+", "")
			if (strStartsWith(line,"\"") and strEndsWith(line,"\"")) then
				--table.insert(CL.mods,string.sub(line,2,-2))
				local modPath = string.sub(line,2,-2)
				CL.println("Loading "..modPath)
				
				local manifestFile=io.open(modPath.."/Manifest.txt","r")
				if manifestFile~=nil then 
					CL.println("Found Manifest for  "..modPath)
					local ScriptFile = nil
					local ScriptClass = nil
					for manifestLine in manifestFile:lines() do
						manifestLine = manifestLine:gsub("%s+", "")
						if (strStartsWith(manifestLine,"ScriptFile=\"") and strEndsWith(manifestLine,"\"")) then
							ScriptFile = string.sub(manifestLine, 13, -2)
							CL.println("ScriptFile="..manifestLine)
						elseif (strStartsWith(manifestLine,"ScriptClass=\"") and strEndsWith(manifestLine,"\"")) then
							ScriptClass = string.sub(manifestLine, 14, -2)
							CL.println("ScriptClass="..manifestLine)
						end
					end
					local ScriptMod = nil
					if (ScriptFile~=nil) and (ScriptClass~=nil) then
						include(ScriptFile)
						if _G[ScriptClass] and _G[ScriptClass].new then
							ScriptMod = _G[ScriptClass].new()
						else
							NKError("Couldn't initialize "..tostring(ScriptClass).." from "..(modPath..ScriptFile).."!")
						end
					end
					table.insert(CL.tugMods, {instance = ScriptMod, fileName = ScriptFile, className = ScriptClass, path = modPath})
				end
			end
		end
		io.close(file)
	else
		NKError("Couldn't load Config/mods.txt")
	end
end

CL:initializeMods()
CL:initializeHooks()