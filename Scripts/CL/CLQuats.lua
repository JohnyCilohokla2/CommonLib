if CL == nil then
	NKError("Common Lib error, initializing module outside of CL.lua!")
end

if (CL.dir == nil) then
	CL.println("Common Lib - Initializing Quats")
	CL.dir = {};
	
	CL.dir.YPos = quat.new(0.707107,0.707107,0,0);
	CL.dir.YNeg = quat.new(0.707107,-0.707107,0,0);
	CL.dir.ZPos = quat.new(1,0,0,0);
	CL.dir.ZNeg = quat.new(0,0,1,0);
	CL.dir.XPos = quat.new(0.707107,0,-0.707107,0);
	CL.dir.YNeg = quat.new(0.707107,0,0.707107,0);
	
	CL.dir.UP = CL.dir.YPos;
	CL.dir.DOWN = CL.dir.YNeg;
end