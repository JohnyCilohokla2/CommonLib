
if (CL.FrameLayouts == nil) then
	CL.println("Common Lib - Initizing FrameLayouts")
	CL.FrameLayouts = {};
	CL.FrameLayouts.cache = {};
end

function CL.FrameLayouts.parse(file)
	CL.println("Getting FrameLayouts",file)
	if (CL.FrameLayouts.cache[file] == nil) then
		local value, err = CL.IDS("Mods/SteamPower/Config/"..file)
		CL.FrameLayouts.cache[file] = value.targets
		CL.println("Parsed",value.name,file)
	end
	return CL.FrameLayouts.cache[file]
end