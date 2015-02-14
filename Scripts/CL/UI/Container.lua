include("Scripts/Core/Common.lua")

local Windows = EternusEngine.UI.Windows 
-------------------------------------------------------------------------------
if CL_UIContainer == nil then
	CL_UIContainer = EternusEngine.Class.Subclass("CL_UIContainer")
end

-------------------------------------------------------------------------------
function CL_UIContainer:Constructor( args )
	self.m_window = nil -- main container for the Window (in CEGUI all GUI elements extending Window class)
	self:PostLoad(args) -- calls PostLoad which initializes the GUI
end

-------------------------------------------------------------------------------
function CL_UIContainer:PostLoad( args ) -- extend this function to implement the GUI
	
end

-------------------------------------------------------------------------------
-- show the main container (and all attached GUI container/components)
-------------------------------------------------------------------------------
function CL_UIContainer:Show(  )
	self.m_window:show()
end

-------------------------------------------------------------------------------
-- hide the main container (and all attached GUI container/components)
-------------------------------------------------------------------------------
function CL_UIContainer:Hide( )
	self.m_window:hide()
end

-------------------------------------------------------------------------------
 -- set position as % of the screen size, only first 2 arguments are required
 -- example: CL_UIContainer:SetPosition( 0.1, 0.2 ) will set the X, Y position to 10%, 20% of the screen size
-------------------------------------------------------------------------------
function CL_UIContainer:SetPosition( xRelative, yRelative, xAbsolute, yAbsolute )

	local xAbs = xAbsolute
	local yAbs = yAbsolute

	if not xAbs then
		xAbs = 0
	end

	if not yAbs then
		yAbs = 0
	end

	self.m_window:setPosition(CEGUI.UVector2(CEGUI.UDim(xRelative, xAbs), CEGUI.UDim(yRelative, yAbs)))
end

-------------------------------------------------------------------------------
 -- set X position as % of the screen width, only first argument is required 
 -- example: CL_UIContainer:SetXPosition( 0.1 ) will set the X position to 10% of the screen width
-------------------------------------------------------------------------------
function CL_UIContainer:SetXPosition( xRelative, xAbsolute )

	local xAbs = xAbsolute

	if not xAbs then
		xAbs = 0
	end

	self.m_window:setXPosition(CEGUI.UDim(xRelative, xAbs))
end

-------------------------------------------------------------------------------
 -- set Y position as % of the screen height, only first argument is required
 -- example: CL_UIContainer:SetYPosition( 0.1 ) will set the Y position to 10% of the screen height
-------------------------------------------------------------------------------
function CL_UIContainer:SetYPosition( yRelative, yAbsolute )

	local yAbs = yAbsolute

	if not yAbs then
		yAbs = 0
	end

	self.m_window:setYPosition(CEGUI.UDim(yRelative, yAbs))
end

-------------------------------------------------------------------------------
 -- set size as % of the screen size, only first 2 arguments are required
 -- example: CL_UIContainer:SetSize( 0.1, 0.2 ) will set the Height, Width to 10%, 20% of the screen size
-------------------------------------------------------------------------------
function CL_UIContainer:SetSize( hRelative, wRelative, hAbsolute, wAbsolute )

	local hAbs = hAbsolute
	local wAbs = wAbsolute

	if not hAbs then
		hAbs = 0
	end

	if not wAbs then
		wAbs = 0
	end

	self.m_window:setSize(CEGUI.USize(CEGUI.UDim(wRelative, wAbs), CEGUI.UDim(hRelative, hAbs)))
end

-------------------------------------------------------------------------------
 -- set height as % of the screen height, only first argument is required
 -- example: CL_UIContainer:SetHeight( 0.1 ) will set the Height to 10% of the screen size
-------------------------------------------------------------------------------
function CL_UIContainer:SetHeight( hRelative, hAbsolute )

	local hAbs = hAbsolute

	if not hAbs then
		hAbs = 0
	end

	self.m_window:setHeight(CEGUI.UDim(hRelative, hAbs))
end

-------------------------------------------------------------------------------
 -- set width as % of the screen width, only first argument is required
 -- example: CL_UIContainer:SetWidth( 0.2 ) will set the Width to 20% of the screen size
-------------------------------------------------------------------------------
function CL_UIContainer:SetWidth( wRelative, wAbsolute )

	local wAbs = wAbsolute

	if not wAbs then
		wAbs = 0
	end

	self.m_window:setHeight(CEGUI.UDim(wRelative, wAbs))
end