include("Scripts/Core/Common.lua")
include("Scripts/CL/UI/Container.lua")

local Windows = EternusEngine.UI.Windows

-------------------------------------------------------------------------------
if CL_DebuggingBox == nil then
	CL_DebuggingBox = CL_UIContainer.Subclass("CL_DebuggingBox")
end

-------------------------------------------------------------------------------
-- No idea what it does... 
-------------------------------------------------------------------------------
function CL_DebuggingBox:Underp()
	NKError("Prog bar underp.")
end

-------------------------------------------------------------------------------
-- Initializing the Debugging Box
-------------------------------------------------------------------------------
function CL_DebuggingBox:PostLoad( args )

	-- create and setup the window
	self.m_window = Windows:createWindow("TUGLook/StaticImage", "DebuggingBox") -- create new window using the TUGLook/StaticImage scheme
	self.m_window:setProperty("BackgroundEnabled", "false") -- configure the background for image
	self.m_window:setProperty("FrameEnabled", "false") -- configure the background for image
	self.m_window:setProperty("Image", "CL/DebuggingBox") -- set the background image
	
	
	self.m_text = Windows:createWindow("TUGLook/StaticText") -- create new window using the TUGLook/StaticText scheme
	self.m_window:addChild(self.m_text) -- add it to the DebuggingBox
	
	self.m_text:setArea(CEGUI.UDim(0.04,0), CEGUI.UDim(0.04,0), CEGUI.UDim(0.92,0), CEGUI.UDim(0.92,0)) -- set the dimentions
	self.m_text:setHeight(CEGUI.UDim(1,0)) -- set the height
	self.m_text:setProperty("HorzFormatting", "WordWrapLeftAligned") -- set the words to wrap and left align
	self.m_text:setProperty("VertFormatting", "TopAligned") -- set the text to top
	self.m_text:setProperty("BackgroundEnabled", "false") -- configure the background
	self.m_text:setProperty("FrameEnabled", "false") -- configure the background

	EternusEngine.UI.Layers.Gameplay:addChild(self.m_window) -- add it to the GamePlay window
end

-------------------------------------------------------------------------------
-- Change the background image 
-------------------------------------------------------------------------------
function CL_DebuggingBox:SetImageItem( item )
	self.m_window:setProperty("Image", item:GetIcon()) -- set the background image 
end

-------------------------------------------------------------------------------
-- Change the text
-------------------------------------------------------------------------------
function CL_DebuggingBox:SetText( text )
	self.m_text:setText(text)
end
