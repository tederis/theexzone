local sw, sh = guiGetScreenSize()

local DEFAULT_DURATION = 15000

xrNewsWindow = {
    bias = 0.3,
    color = tocolor( 245, 255, 250 ),
    messages = {}
}

function xrNewsWindow:setup( canvas )
    if self.initialized then
        return false
    end

    self.list = canvas:getFrame( "MessagesList", true ):setChildLimit( 4 ):setGapHeight( 15 )
    
    self.entryXml = xmlLoadFile( "config/NewsEntry.xml", true )    
    
    self.canvas = canvas
    self.initialized = true    
end

function xrNewsWindow:destroy()
    if not self.initialized then
        return
    end

    xmlUnloadFile( self.entryXml )

    self.initialized = nil
end

function xrNewsWindow:draw( dt )
    if not self.initialized then
        return
    end
end

function xrNewsWindow:update()
    local now = getTickCount()
    local lastEntry = self.list.items[ #self.list.items ]
    if lastEntry and now - lastEntry.startTime > DEFAULT_DURATION then
        lastEntry:destroy()
    end
end

function xrNewsWindow:print( text, textureSectionName )
    if self.entryXml then
        local frame = self.canvas:insert( self.entryXml, self.list, true )
        frame.startTime = getTickCount()

        local hours, mins = getTime()
        frame:getFrame( "Time" ):setText( hours .. ":" .. mins )
        frame:getFrame( "Desc" ):setText( text )
        frame:getFrame( "Img" ):setTexture( "ui_actor_newsmanager_icons" )
        frame:getFrame( "Img" ):setTextureSection( textureSectionName )

        self.canvas:update()

        playSound( "sounds/pda_news.ogg" )
    end
end

function xrNewsWindow:hideAll()
    
end