xrIncludeModule( "uisection.lua" )

--[[
    UIColorDict
]]
xrColors = {

}

function xrLoadUIColorDict( name )
    local filename = ":xrcore/config/ui/" .. name .. ".xml"
    
    local xml = xmlLoadFile( filename, true )
    if not xml then
        return false
    end

    for _, child in ipairs( xmlNodeGetChildren( xml ) ) do
        if xmlNodeGetName( child ) == "color" then
            local name = xmlNodeGetAttribute( child, "name" )
            local r = tonumber( xmlNodeGetAttribute( child, "r" ) ) or 0
            local g = tonumber( xmlNodeGetAttribute( child, "g" ) ) or 0
            local b = tonumber( xmlNodeGetAttribute( child, "b" ) ) or 0
            local color = tocolor( r, g, b )

            xrColors[ name ] = color
        end
    end

    xmlUnloadFile( xml )

    return true
end

--[[
    UIDescriptor
]]
local STICK_RIGHT = 1
local STICK_LEFT = 2
local STICK_TOP = 1
local STICK_BOTTOM = 2
local STICK_CENTER = 3

local ASPECT_WIDTH = 1
local ASPECT_HEIGHT = 2

local ANCHOR_KEEP = 1
local ANCHOR_CENTER = 2

local ALIGN_CENTER = 1

local PIVOT_CENTER = 1

local WRAP_CONTENT = 1

UIDescriptor = {

}
UIDescriptorMT = {
    __index = UIDescriptor
}

function UIDescriptor:create( px, py, pw, ph )
    local x, y, w, h = UIDescriptor.transformed( self, px, py, pw, ph )
    
    self.tx = x
    self.ty = y
    self.tw = w
    self.th = h
end

function UIDescriptor:transformed( px, py, pw, ph )
    local canvas = self.canvas
    local parent = self.parent    
    
    local tx, ty = self.x, self.y
    local tw, th = self.width, self.height

    if parent and self.anchor == ANCHOR_KEEP then
        local rx = self.x / parent.width
        local ry = self.y / parent.height
        local rw = self.width / parent.width
        local rh = self.height / parent.height

        tx = pw * rx
        ty = ph * ry
        tw = pw * rw
        th = ph * rh    
    end

    if self.aspect == ASPECT_WIDTH then
        tw = math.floor( ( self.width / canvas.width ) * canvas.screenWidth )
        local aspect = self.height / self.width
        th = tw * aspect
    elseif self.aspect == ASPECT_HEIGHT then
        th = math.floor( ( self.height / canvas.height ) * canvas.screenHeight )
        local aspect = self.width / self.height
        tw = th * aspect
    end

    if parent and self.anchor == ANCHOR_CENTER then
        local rx = pw / 2 - tw / 2
        local ry = ph / 2 - th / 2

        tx = rx
        ty = ry  
    else
        if self.stickH == STICK_RIGHT then
            local bias = canvas.width - ( self.x + self.width )
            tx = canvas.screenWidth - tw - bias
        elseif self.stickH == STICK_LEFT then
            local bias = self.x
            tx = bias
        elseif self.stickH == STICK_CENTER then
            tx = ( canvas.screenWidth / 2 ) - ( tw / 2 )
        end
        if self.stickV == STICK_BOTTOM then
            local bias = canvas.height - ( self.y + self.height )
            ty = canvas.screenHeight - th - bias
        elseif self.stickV == STICK_TOP then
            local bias = self.y
            ty = bias
        elseif self.stickV == STICK_CENTER then
            ty = ( canvas.screenHeight / 2 ) - ( th / 2 )
        end
    end

    --dxDrawRectangle( px + tx, py + ty, tw, th, tocolor( 255, 200, 200, 200 ) )

    return px + tx, py + ty, tw, th
end

function UIDescriptor:setSize( width, height )
    self.width = width
    self.height = height
end

function UIDescriptor:draw( px, py, pw, ph )
    if not self.visible then
        return
    end

    local x, y, width, height = self:transformed( px, py, pw, ph )
    
    for _, child in ipairs( self.items ) do
        child:draw(  x, y, width, height )
    end
end

--[[
    UIImage
]]
UIImage = {

}
UIImageMT = {
    __index = UIImage
}
setmetatable( UIImage, UIDescriptorMT )

function UIImage:load( xmlnode )

end

function UIImage:draw( px, py, pw, ph )
    if not self.visible then
        return
    end

    local x, y, width, height = self:transformed( px, py, pw, ph )

    local textureDesc = self.texSection
    if textureDesc then
        if self.u and self.vs then
            textureDesc:drawSection( self.canvas.textures, x, y, width, height, self.u, self.v, self.us, self.vs )
        else
            textureDesc:draw( self.canvas.textures, x, y, width, height )
        end
    elseif self.tex then
        dxDrawImage( x, y, width, height, self.tex )
    end
    
    for _, child in ipairs( self.items ) do
        child:draw( x, y, width, height )
    end
end

function UIImage:setUV( x, y, width, height )
    self.u = x
    self.v = y
    self.us = width
    self.vs = height
end

function UIImage:setTexture( texture )
    self.tex = texture
end

function UIImage:setTextureSection( textureDesc )
    local texture = xrTextureSections[ textureDesc ]
    if texture then
        self.texSection = texture
    end
end

--[[
    UIProgressBar
]]
UIProgressBar = {

}
UIProgressBarMT = {
    __index = UIProgressBar
}
setmetatable( UIProgressBar, UIDescriptorMT )

function UIProgressBar:load( xmlnode )
    
end

function UIProgressBar:draw( px, py, pw, ph )
    if not self.visible then
        return
    end

    local x, y, width, height = self:transformed( px, py, pw, ph )

    local textureDesc = self.texSection
    if textureDesc and self.x and self.height then
        textureDesc:drawProgress( self.canvas.textures, x, y, width, height, self.pos / 100 )
    end
    
    for _, child in ipairs( self.items ) do
        child:draw( x, y, width, height )
    end
end

function UIProgressBar:setPosition( pos )
    self.pos = math.max( math.min( pos, self.max ), self.min )
end

--[[
    UIProgressBar
]]
UIText = {

}
UITextMT = {
    __index = UIText
}
setmetatable( UIText, UIDescriptorMT )

function UIText:load( xmlnode )
    
end

function UIText:draw( px, py, pw, ph )
    if not self.visible then
        return
    end

    local x, y, width, height = self:transformed( px, py, pw, ph )

    local font = self.canvas.fonts[ self.font ] or "clear"

    dxDrawText( tostring( self.text ), x, y, x + width, y + height, self.color, self.scale, font, self.alignX, self.alignY )
    
    for _, child in ipairs( self.items ) do
        child:draw( x, y, width, height )
    end
end

--[[
    UIDragDrop
]]
UIDragDrop = {

}
UIDragDropMT = {
    __index = UIDragDrop
}
setmetatable( UIDragDrop, UIDescriptorMT )

function UIDragDrop:load( xmlnode )
    self.cellWidth = tonumber( xmlNodeGetAttribute( xmlnode, "cell_width" ) )
    self.cellHeight = tonumber( xmlNodeGetAttribute( xmlnode, "cell_height" ) )
    self.rowsNum = tonumber( xmlNodeGetAttribute( xmlnode, "rows_num" ) )
    self.colsNum = tonumber( xmlNodeGetAttribute( xmlnode, "cols_num" ) )
    self.customPl = tonumber( xmlNodeGetAttribute( xmlnode, "custom_placement" ) ) == 1
    self.a = tonumber( xmlNodeGetAttribute( xmlnode, "a" ) ) == 1
    self.virtCells = tonumber( xmlNodeGetAttribute( xmlnode, "virtual_cells" ) )
    self.vertAlign = xmlNodeGetAttribute( xmlnode, "vc_vert_align" )
    self.horAlign = xmlNodeGetAttribute( xmlnode, "vc_horiz_align" )
end

function UIDragDrop:draw( px, py, pw, ph )
    if not self.visible then
        return
    end

    local x, y, width, height = self:transformed( px, py, pw, ph )

    local canvas = self.canvas
    local cellWidth = math.floor( ( self.cellWidth / canvas.width ) * canvas.screenWidth )
    local cellHeight = math.floor( ( self.cellHeight / canvas.height ) * canvas.screenHeight )

    for i = 0, self.colsNum-1 do
		local _x = x + cellWidth*i
		for j = 0, self.rowsNum-1 do
			local _y = y + cellHeight*j
			local biasx = 0
			--[[local item = xrSlotGetItemAt( slot, i, j, false )
			if item and item == env.clickedItem then
				biasx = 64
			end]]
			dxDrawImageSection ( _x, _y, cellWidth, cellHeight, biasx, 0, 64, 64, "textures/ui_grid.dds" )
		end
	end
end

local function _parseTextureNode( frame, xmlnode )
    local texName = xmlNodeGetValue( xmlnode )
    frame.texSection = xrTextureSections[ texName ]
    if not frame.texSection then
        outputDebugString( "Текстура " .. texName .. " не была найдена", 2 )
    end    
end

local function _parseTextNode( frame, xmlnode )
    frame.font = xmlNodeGetAttribute( xmlnode, "font" )

    local colorName = xmlNodeGetAttribute( xmlnode, "color" )
    frame.color = xrColors[ colorName ] or tocolor( 255, 255, 255 )

    local r = tonumber( xmlNodeGetAttribute( xmlnode, "r" ) )
    local g = tonumber( xmlNodeGetAttribute( xmlnode, "g" ) )
    local b = tonumber( xmlNodeGetAttribute( xmlnode, "b" ) )
    local a = tonumber( xmlNodeGetAttribute( xmlnode, "a" ) ) or 255
    if r and g and b then
        frame.color = tocolor( r, g, b, a )
    end

    local alignX = xmlNodeGetAttribute( xmlnode, "alignX" )
    if alignX == "left" or alignX == "center" or alignX == "right" then
        frame.alignX = alignX
    else
        frame.alignX = "left"
    end

    local alignY = xmlNodeGetAttribute( xmlnode, "alignY" )
    if alignY == "top" or alignY == "center" or alignY == "bottom" then
        frame.alignY = alignY
    else
        frame.alignY = "top"
    end   

    frame.text = tostring( xmlNodeGetValue( xmlnode ) )

    local scale = xmlNodeGetAttribute( xmlnode, "scale" )
    frame.scale = tonumber( scale ) or 1
end

local function _parseProgressNode( frame, xmlnode )
    frame.horz = tonumber( xmlNodeGetAttribute( xmlnode, "horz" ) ) == 1
    frame.min = tonumber( xmlNodeGetAttribute( xmlnode, "min" ) ) or 0
    frame.max = tonumber( xmlNodeGetAttribute( xmlnode, "max" ) ) or 100
    frame.pos = tonumber( xmlNodeGetAttribute( xmlnode, "pos" ) ) or 0
end

function xrLoadFrameDescriptor( parentFrame, xmlnode )
    local canvas = parentFrame.canvas

    local visibleValue = xmlNodeGetAttribute( xmlnode, "visible" )

    local frame = {
        canvas = canvas,
        parent = parentFrame,
        x = tonumber( xmlNodeGetAttribute( xmlnode, "x" ) ) or 0,
        y = tonumber( xmlNodeGetAttribute( xmlnode, "y" ) ) or 0,
        width = tonumber( xmlNodeGetAttribute( xmlnode, "width" ) ) or parentFrame.width,
        height = tonumber( xmlNodeGetAttribute( xmlnode, "height" ) ) or parentFrame.height,
        visible = visibleValue == false or visibleValue == "true",

        items = {}
    }

    UIDescriptor.create( frame, parentFrame.tx, parentFrame.ty, parentFrame.tw, parentFrame.th )

    local stickMode = xmlNodeGetAttribute( xmlnode, "stick" ) or ""
    if string.find( stickMode, "l" ) then
        frame.stickH = STICK_LEFT
    elseif string.find( stickMode, "r" ) then
        frame.stickH = STICK_RIGHT
    end
    if string.find( stickMode, "t" ) then
        frame.stickV = STICK_TOP
    elseif string.find( stickMode, "b" ) then
        frame.stickV = STICK_BOTTOM
    end

    stickMode = xmlNodeGetAttribute( xmlnode, "stickH" ) or ""
    if string.find( stickMode, "l" ) then
        frame.stickH = STICK_LEFT
    elseif string.find( stickMode, "r" ) then
        frame.stickH = STICK_RIGHT
    elseif string.find( stickMode, "c" ) then
        frame.stickH = STICK_CENTER
    end

    stickMode = xmlNodeGetAttribute( xmlnode, "stickV" ) or ""
    if string.find( stickMode, "t" ) then
        frame.stickV = STICK_TOP
    elseif string.find( stickMode, "b" ) then
        frame.stickV = STICK_BOTTOM
    elseif string.find( stickMode, "c" ) then
        frame.stickV = STICK_CENTER
    end

    local aspectMode = xmlNodeGetAttribute( xmlnode, "aspect" )
    if aspectMode == "width" then
        frame.aspect = ASPECT_WIDTH
    elseif aspectMode == "height" then
        frame.aspect = ASPECT_HEIGHT
    end

    local anchorMode = xmlNodeGetAttribute( xmlnode, "anchor" )
    if anchorMode == "keep" then
        frame.anchor = ANCHOR_KEEP
    elseif anchorMode == "center" then
        frame.anchor = ANCHOR_CENTER
    end

    local alignMode = xmlNodeGetAttribute( xmlnode, "align" )
    if alignMode == "c" then
        frame.align = ALIGN_CENTER
    end

    local classMt = UIImageMT
    
    for _, child in ipairs( xmlNodeGetChildren( xmlnode ) ) do
        local childName = xmlNodeGetName( child )
        if childName == "texture" then
            _parseTextureNode( frame, child )
            classMt = UIImageMT
        elseif childName == "text" then
            _parseTextNode( frame, child )
            classMt = UITextMT
        elseif childName == "window_name" then
            frame.wndName = xmlNodeGetValue( child )
        elseif childName == "progress" then
            _parseProgressNode( frame, child )
            classMt = UIProgressBarMT
        else
            xrLoadFrameDescriptor( frame, child )
        end
    end

    if xmlNodeGetAttribute( xmlnode, "cell_width" ) or xmlNodeGetAttribute( xmlnode, "rows_num" ) then 
        classMt = UIDragDropMT
    end

    setmetatable( frame, classMt )
    
    frame:load( xmlnode )
       
    local name = xmlNodeGetName( xmlnode )
    canvas.items[ name ] = frame
    table.insert( parentFrame.items, frame )
end

function xrLoadUIDescriptor( name, canvas )
    local filename = ":xrcore/config/ui/" .. name .. ".xml"

    local xml = xmlLoadFile( filename, true )
    if not xml then
        outputDebugString( filename .. " не был найден", 1 )
        return
    end

    local desc = {
        canvas = canvas,
        items = {},
        visible = true,

        x = tonumber( xmlNodeGetAttribute( xml, "x" ) ) or 0,
        y = tonumber( xmlNodeGetAttribute( xml, "y" ) ) or 0,
        width = tonumber( xmlNodeGetAttribute( xml, "width" ) ) or 1024,
        height = tonumber( xmlNodeGetAttribute( xml, "height" ) ) or 768,

        tx = canvas.screenX,
        ty = canvas.screenY,
        tw = canvas.screenWidth,
        th = canvas.screenHeight
    }

    for _, child in ipairs( xmlNodeGetChildren( xml ) ) do
        xrLoadFrameDescriptor( desc, child )
    end

    xmlUnloadFile( xml )

    return setmetatable( desc, UIDescriptorMT )
end

--[[
    UICanvas
]]
UICanvas = {

}
UICanvasMT = {
    __index = UICanvas
}

function UICanvas:draw()
    self.desc:draw( self.screenX, self.screenY, self.screenWidth, self.screenHeight )
end

function UICanvas:loadTexture( name )
    local tex = self.textures[ name ]
    if tex then
        return tex
    end

    tex = dxCreateTexture( "textures/ui/" .. name .. ".dds" )
    self.textures[ name ] = tex

    return tex
end

function UICanvas:loadFont( name, filename, size, bold )
    local font = self.fonts[ name ]
    if font then
        return font
    end

    font = dxCreateFont( filename, tonumber( size ) or 9, bold == true )
    self.fonts[ name ] = font
    
    return font
end

function UICanvas:unloadTextures()
    for _, tex in pairs( self.textures ) do
        destroyElement( tex )
    end 
end

function UICanvas:unloadFonts()
    for _, font in pairs( self.fonts ) do
        destroyElement( font )
    end
    self.fonts = {}
end

function UICanvas:setFrameEnabled( key, state )
    local frame = self.items[ key ]
    if frame then
        frame.visible = state
    end
end

function UICanvas:getFrame( key )
    return self.items[ key ]
end

function xrCreateUICanvas( name, x, y, width, height, screenWidth, screenHeight, screenX, screenY )
    local canvas = {
        textures = {},
        fonts = {},
        items = {
            -- Глобальный кэш фреймов
        },
        x = x, y = y,
        width = width,
        height = height,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        screenX = tonumber( screenX ) or 0,
        screenY = tonumber( screenY ) or 0
    }

    canvas.desc = xrLoadUIDescriptor( name, canvas )

    return setmetatable( canvas, UICanvasMT )
end