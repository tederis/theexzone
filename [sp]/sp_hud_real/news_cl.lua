local sw, sh = guiGetScreenSize()

local DEFAULT_DURATION = 2000

xrNewsWindow = {
    bias = 0.3,
    color = tocolor( 245, 255, 250 ),
    messages = {}
}

function xrNewsWindow:setup()
    if self.initialized then
        return false
    end

    self.canvas = xrCreateUICanvas( 0, 0, sw, sh )

    local xml = xmlLoadFile( "config/NewsManager.xml", true )
	if xml then
		self.canvas:load( xml )

		xmlUnloadFile( xml )
    end
    
    self.canvas:update()

    self.initialized = true
end

function xrNewsWindow:destroy()
    if not self.initialized then
        return
    end

    self.initialized = nil
end

function xrNewsWindow:draw( dt )
    if not self.initialized then
        return
    end

    self.canvas:draw()
end

function xrNewsWindow:update()
    
end

function xrNewsWindow:print( text )
   
end

function xrNewsWindow:hideAll()
    
end