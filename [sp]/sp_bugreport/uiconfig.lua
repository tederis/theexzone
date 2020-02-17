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

local defaultFontsLookup = {
    [ "default" ] = true,
    [ "default-bold" ] = true,
    [ "clear" ] = true,
    [ "arial" ] = true,
    [ "sans" ] = true,
    [ "pricedown" ] = true,
    [ "bankgothic" ] = true,
    [ "diploma" ] = true,
    [ "beckett" ] = true
}


--[[
    UIFrameFactory
]]
UIFrameFactory = {

}

function UIFrameFactory:create( frameType )
    local frame

    if frameType == "frame" then
        frame = UIDescriptor:create()
    elseif frameType == "image" then
        frame = UIImage:create()
    elseif frameType == "button" then
        frame = UIButton:create()
    elseif frameType == "form" then
        frame = UIForm:create()
    elseif frameType == "list" then
        frame = UIList:create()
    elseif frameType == "scrollpane" then
        frame = UIScrollPane:create()
    elseif frameType == "progress" then        
        frame = UIProgressBar:create()
    elseif frameType == "text" then
        frame = UIText:create()
    elseif frameType == "scrollbar" then
        frame = UIScrollBar:create()
    elseif frameType == "rt" then
        frame = UIRenderTarget:create()
    elseif frameType == "editfield" then
        frame = UIEditField:create()
    end

    if frame then
        return frame
    else
        outputDebugString( "Инвалидный тип фрейма " .. tostring( frameType ), 2 )
    end

    return false
end


--[[
    UIDescriptor
]]
UIDescriptor = {
    typeName = "frame"
}
UIDescriptorMT = {
    __index = UIDescriptor
}

function UIDescriptor:create( name, x, y, width, height )
   local frame = {
        name = tostring( name or "default" ),
        items = {},
        visible = true,
        selected = false,

        anchorLeftTopX = 0,
        anchorLeftTopY = 0,
        anchorRightBottomX = 1,
        anchorRightBottomY = 1,

        originX = tonumber( x ) or 0,
        originY = tonumber( y ) or 0,
        originWidth = tonumber( width ) or 1024,
        originHeight = tonumber( height ) or 768
    }

    return setmetatable( frame, UIDescriptorMT )
end

function UIDescriptor:destroy()
    --[[
        Чтобы мы могли в момент удаления беззаботно манипулировать
        дочерними фреймами делаем копию
    ]]
    local frames = table.copy( self.items, false )

    for _, frame in ipairs( frames ) do
        frame:destroy()
    end

    local parent = self.parent
    if parent then
        parent:onChildRemoved( self )
    end

    self.canvas:onFrameRemoved( self )

    self.name = nil
    self.parent = nil
    self.canvas = nil
    self.items = nil
end

function UIDescriptor:load( xml )
    local name = xmlNodeGetAttribute( xml, "name" )
    if name then
        self.name = tostring( name )
    end

    self.visible = xmlNodeGetAttribute( xml, "visible" ) == "true"

    local anchorNode = xmlFindChild( xml, "anchor", 0 )
    if anchorNode then
        local value = tonumber( xmlNodeGetAttribute( anchorNode, "leftTopX" ) )
        if value then
            self.anchorLeftTopX = value
        end
        value = tonumber( xmlNodeGetAttribute( anchorNode, "leftTopY" ) )
        if value then
            self.anchorLeftTopY = value
        end
        value = tonumber( xmlNodeGetAttribute( anchorNode, "rightBottomX" ) )
        if value then
            self.anchorRightBottomX = value
        end
        value = tonumber( xmlNodeGetAttribute( anchorNode, "rightBottomY" ) )
        if value then
            self.anchorRightBottomY = value
        end
    end

    local originNode = xmlFindChild( xml, "origin", 0 )
    if originNode then
        local value = tonumber( xmlNodeGetAttribute( originNode, "x" ) )
        if value then
            self.originX = value
        end
        value = tonumber( xmlNodeGetAttribute( originNode, "y" ) )
        if value then
            self.originY = value
        end
        value = tonumber( xmlNodeGetAttribute( originNode, "width" ) )
        if value then
            self.originWidth = value
        end
        value = tonumber( xmlNodeGetAttribute( originNode, "height" ) )
        if value then
            self.originHeight = value
        end
    end

    local index = 0
    local xmlnode = xmlFindChild( xml, "frame", index )
    while xmlnode do
        local frameType = xmlNodeGetAttribute( xmlnode, "type" )
        local frame = UIFrameFactory:create( frameType )
        if frame then
            frame.canvas = self.canvas
            frame.parent = self            

            frame:load( xmlnode )

            self:insertChild( frame )
        end

        index = index + 1
        xmlnode = xmlFindChild( xml, "frame", index )
    end
end

function UIDescriptor:save( xml )
    xmlNodeSetAttribute( xml, "type", tostring( self.typeName ) )
    xmlNodeSetAttribute( xml, "name", tostring( self.name ) )
    xmlNodeSetAttribute( xml, "visible", self.visible == true and "true" or "false" )
    
    local anchorNode = xmlCreateChild( xml, "anchor" )
    xmlNodeSetAttribute( anchorNode, "leftTopX", tostring( self.anchorLeftTopX ) )
    xmlNodeSetAttribute( anchorNode, "leftTopY", tostring( self.anchorLeftTopY ) )
    xmlNodeSetAttribute( anchorNode, "rightBottomX", tostring( self.anchorRightBottomX ) )
    xmlNodeSetAttribute( anchorNode, "rightBottomY", tostring( self.anchorRightBottomY ) )

    local originNode = xmlCreateChild( xml, "origin" )
    xmlNodeSetAttribute( originNode, "x", tostring( self.originX ) )
    xmlNodeSetAttribute( originNode, "y", tostring( self.originY ) )
    xmlNodeSetAttribute( originNode, "width", tostring( self.originWidth ) )
    xmlNodeSetAttribute( originNode, "height", tostring( self.originHeight ) )

    for _, child in ipairs( self.items ) do
        local frameNode = xmlCreateChild( xml, "frame" )

        child:save( frameNode )
    end
end

function UIDescriptor:insertChild( frame )
    table.insert( self.items, frame )

    return self
end

function UIDescriptor:createChild( frameType, name )
    local frame = UIFrameFactory:create( frameType )
    if frame then
        frame.name = name
        frame.parent = self
        frame.canvas = self.canvas

        self:insertChild( frame )

        return frame
    end
end

function UIDescriptor:onChildRemoved( removedFrame )
    table.removeValue( self.items, removedFrame )
end

function UIDescriptor:onCursorMove( ax, ay )
    if not self.canvas.focusLock then
        self.selected = false
    end

    local force = self.canvas.focusLock and self.selected
    if self.visible and ( force or isPointInRect( ax, ay, self.tx, self.ty, self.tw, self.th ) ) then
        if not self.canvas.focusLock then
            self.selected = true
            self.canvas.focused = self
        end

        if not self.inhibitPropagation then
            for _, child in ipairs( self.items ) do
                child:onCursorMove( ax, ay )
            end
        end
    end
end

function UIDescriptor:onCursorEnter( ax, ay )
    
end

function UIDescriptor:onCursorExit( ax, ay )

end

function UIDescriptor:onCursorClick( btn, state, ax, ay )  
    if self.inhibitPropagation then
        return
    end
      
    for _, child in ipairs( self.items ) do
        if child.visible and child.selected then
            child:onCursorClick( btn, state, ax, ay )
        end
    end
end

HOR_MODE_LEFT = 1
HOR_MODE_CENTER = 2
HOR_MODE_RIGHT = 3
HOR_MODE_STRETCH = 4
VERT_MODE_TOP = 1
VERT_MODE_CENTER = 2
VERT_MODE_BOTTOM = 3
VERT_MODE_STRETCH = 4

function UIDescriptor:applyTransform( x, y, width, height, anchored )
    self.originX = x
    self.originY = y
    self.originWidth = width
    self.originHeight = height

    local parent = self.parent
    if parent then 
        if anchored then
            self.anchorLeftTopX = x / parent.originWidth
            self.anchorLeftTopY = y / parent.originHeight
            self.anchorRightBottomX = ( x + width ) / parent.originWidth
            self.anchorRightBottomY = ( y + height ) / parent.originHeight
        else
            local cx = ( x + width/2 ) / parent.originWidth
            local cy = ( y + height/2 ) / parent.originHeight

            self.anchorLeftTopX = cx
            self.anchorLeftTopY = cy
            self.anchorRightBottomX = cx
            self.anchorRightBottomY = cy
        end
    end

    return self
end

function UIDescriptor:onVisibleChange( visible )

end

function UIDescriptor:setVisible( visible )
    self.visible = visible
    self:onVisibleChange( visible )

    for _, child in ipairs( self.items ) do
        child:setVisible( visible )
    end

    return self
end

function UIDescriptor:setPosition( x, y )
    self.originX = x
    self.originY = y

    return self
end

function UIDescriptor:setSize( width, height )
    self.originWidth = width
    self.originHeight = height

    return self
end

function UIDescriptor:setAnchorLeftTop( anchorX, anchorY )
    self.anchorLeftTopX = anchorX
    self.anchorLeftTopY = anchorY

    return self
end

function UIDescriptor:setAnchorRightBottom( anchorX, anchorY )
    self.anchorRightBottomX = anchorX
    self.anchorRightBottomY = anchorY

    return self
end

function UIDescriptor:setHorizontalAlign( align )
    if align == HOR_MODE_LEFT then
        self.anchorLeftTopX = 0
        self.anchorRightBottomX = 0
    elseif align == HOR_MODE_CENTER then
        self.anchorLeftTopX = 0.5
        self.anchorRightBottomX = 0.5
    elseif align == HOR_MODE_RIGHT then
        self.anchorLeftTopX = 1
        self.anchorRightBottomX = 1
    elseif align == HOR_MODE_STRETCH then
        self.anchorLeftTopX = 0
        self.anchorRightBottomX = 1
    end      

    return self 
end

function UIDescriptor:setVerticalAlign( align )
    if align == VERT_MODE_TOP then
        self.anchorLeftTopY = 0
        self.anchorRightBottomY = 0
    elseif align == VERT_MODE_CENTER then
        self.anchorLeftTopY = 0.5
        self.anchorRightBottomY = 0.5
    elseif align == VERT_MODE_BOTTOM then
        self.anchorLeftTopY = 1
        self.anchorRightBottomY = 1
    elseif align == VERT_MODE_STRETCH then
        self.anchorLeftTopY = 0
        self.anchorRightBottomY = 1
    end 

    return self
end

function UIDescriptor:getTransform()
    return self.originX, self.originY, self.originWidth, self.originHeight
end

function UIDescriptor:getFrame( key, recursive )
    for _, child in ipairs( self.items ) do
        if child.name == key then
            return child
        elseif recursive then
            local result = child:getFrame( key, recursive )
            if result then
                return result
            end
        end
    end

    return false
end

function UIDescriptor:draw()
    if not self.visible then
        return
    end
    
    for _, child in ipairs( self.items ) do
        child:draw()
    end
end

function UIDescriptor:update()
    local fx, fy, fwidth, fheight = self:getTransform()

    local parent = self.parent
    if parent then
        local px, py, pwidth, pheight = parent:getTransform()

        local originLeft = fx - self.anchorLeftTopX * pwidth
        local originRight = ( fx + fwidth ) - self.anchorRightBottomX * pwidth
        local originTop = fy - self.anchorLeftTopY * pheight
        local originBottom = ( fy + fheight ) - self.anchorRightBottomY * pheight

        local leftTopX = parent.tx + self.anchorLeftTopX * parent.tw + originLeft
        local rightBottomX = parent.tx + self.anchorRightBottomX * parent.tw + originRight
        local width = rightBottomX - leftTopX

        local leftTopY = parent.ty + self.anchorLeftTopY * parent.th + originTop
        local rightBottomY = parent.ty + self.anchorRightBottomY * parent.th + originBottom
        local height = rightBottomY - leftTopY

        self.tx = leftTopX
        self.ty = leftTopY
        self.tw = width
        self.th = height
    else
        self.tx = self.canvas.screenX
        self.ty = self.canvas.screenY
        self.tw = self.canvas.screenWidth
        self.th = self.canvas.screenHeight
    end
end

function UIDescriptor:forward()
    self:update()

    for _, child in ipairs( self.items ) do
        child:forward()
    end
end

--[[
    UIForm
]]
UIForm = {
    typeName = "form"
}
UIFormMT = {
    __index = UIForm
}
setmetatable( UIForm, UIDescriptorMT )

function UIForm:create( name, x, y, width, height )
    local frame = UIDescriptor:create( name, x, y, width, height )

    return setmetatable( frame, UIFormMT )
end

function UIForm:load( xml )
    UIDescriptor.load( self, xml )
end

function UIForm:save( xml )
    UIDescriptor.save( self, xml )
end

function UIForm:update()
    UIDescriptor.update( self )

    local maxX, maxY

    for _, child in ipairs( self.items ) do
        child:forward()

        maxX = math.max( maxX or ( child.tx + child.tw ), child.tx + child.tw )
        maxY = math.max( maxY or ( child.ty + child.th ), child.ty + child.th )
    end

    if maxX and maxY then
        local height = maxY - self.ty
        
        self.th = height
    end
end

--[[
    UIList
]]
UIList = {
    typeName = "list"
}
UIListMT = {
    __index = UIList
}
setmetatable( UIList, UIDescriptorMT )

function UIList:create( name, x, y, width, height )
    local frame = UIDescriptor:create( name, x, y, width, height )

    return setmetatable( frame, UIListMT )
end

function UIList:load( xml )
    UIDescriptor.load( self, xml )
end

function UIList:save( xml )
    UIDescriptor.save( self, xml )
end

function UIList:forward()
    self:update()

    local y = self.ty

    for _, child in ipairs( self.items ) do
        child:update()

        child.ty = y        

        for _, subchild in ipairs( child.items ) do
            subchild:forward()            
        end

        y = y + child.th
    end
end

--[[
    UIImage
]]
UIImage = {
    typeName = "image"
}
UIImageMT = {
    __index = UIImage
}
setmetatable( UIImage, UIDescriptorMT )

function UIImage:create( name, x, y, width, height )
    local frame = UIDescriptor:create( name, x, y, width, height )
    frame.rot = 0
    frame.rotOffsetX = 0
    frame.rotOffsetY = 0
    frame.tex = nil
    frame.texSection = nil
    frame.texName = ""
    frame.shader = nil

    return setmetatable( frame, UIImageMT )
end

function UIImage:load( xml )
    local textureName = xmlNodeGetAttribute( xml, "texture" )
    if textureName then
        self:setTexture( textureName )
    end

    local sectionName = xmlNodeGetAttribute( xml, "section" )
    if sectionName then
        self:setTextureSection( sectionName )
    end

    UIDescriptor.load( self, xml )
end

function UIImage:save( xml )
    if self.tex then
        xmlNodeSetAttribute( xml, "texture", tostring( self.texName ) )
    end
    if self.texSection then
        xmlNodeSetAttribute( xml, "section", tostring( self.texSection.id ) )
    end

    UIDescriptor.save( self, xml )
end

function UIImage:draw()
    if not self.visible then
        return
    end

    local texture = self.shader or self.tex
    if texture then
        local textureSection = self.texSection
        if textureSection then
            if self.u and self.vs then
                textureSection:drawSection( texture, self.tx, self.ty, self.tw, self.th, self.u, self.v, self.us, self.vs, self.rot, self.rotOffsetX, self.rotOffsetY )
            else
                textureSection:draw( texture, self.tx, self.ty, self.tw, self.th, self.rot, self.rotOffsetX, self.rotOffsetY )
            end
        else
            if self.u and self.vs then
                dxDrawImageSection( self.tx, self.ty, self.tw, self.th, self.u, self.v, self.us, self.vs, texture, self.rot, self.rotOffsetX, self.rotOffsetY )
            else
                dxDrawImage( self.tx, self.ty, self.tw, self.th, texture, self.rot, self.rotOffsetX, self.rotOffsetY )
            end
        end
    end
    
    for _, child in ipairs( self.items ) do
        child:draw()
    end
end

function UIImage:setUV( x, y, width, height )
    self.u = x
    self.v = y
    self.us = width
    self.vs = height
end

function UIImage:setTexture( textureName )
    local tex = exports.sp_assets:xrLoadAsset( textureName )
    if tex then
        self.tex = tex
        self.texName = textureName -- Для сохранения

        if self.shader then
            dxSetShaderValue( self.shader, "Tex0", tex )
        end
    else
        outputDebugString( "Текстуры с именем " .. tostring( textureName ) .. " не существует!", 2 )
    end
end

function UIImage:setTextureSection( sectionName )
    local section = xrTextureSections[ sectionName ]
    if section then
        self.texSection = section
    else
        outputDebugString( "Текстурной секции " .. sectionName .. " не существует!", 2 )
    end
end

function UIImage:setRotationOffset( offsetX, offsetY )
    self.rotOffsetX = tonumber( offsetX ) or 0
    self.rotOffsetY = tonumber( offsetY ) or 0
end

function UIImage:setRotation( rot )
    self.rot = tonumber( rot ) or 0
end

function UIImage:setShader( shader )
    self.shader = shader

    if self.tex then
        dxSetShaderValue( shader, "Tex0", self.tex )
    end
end

--[[
    UIRenderTarget
]]
UIRenderTarget = {
    typeName = "rt",
    noticeable = true
}
UIRenderTargetMT = {
    __index = UIRenderTarget
}
setmetatable( UIRenderTarget, UIDescriptorMT )

function UIRenderTarget:create( name, x, y, width, height )
    local frame = UIDescriptor:create( name, x, y, width, height )
    frame._rt = false
    frame.targetCanvas = nil
    frame.shader = nil

    return setmetatable( frame, UIRenderTargetMT )
end

function UIRenderTarget:destroy()
    if self._rt then
        destroyElement( self._rt )
    end

    UIDescriptor.destroy( self )
end

function UIRenderTarget:load( xml )
    UIDescriptor.load( self, xml )
end

function UIRenderTarget:save( xml )
    UIDescriptor.save( self, xml )
end

function UIRenderTarget:draw()
    if not self.visible then
        return
    end

    local targetCanvas = self.targetCanvas
    local renderTarget = self._rt

    if targetCanvas and renderTarget then
        dxSetRenderTarget( renderTarget, true )
        targetCanvas:draw()
        dxSetRenderTarget()

        if self.shader then
            dxDrawImage( self.tx, self.ty, self.tw, self.th, self.shader )
        else
            dxDrawImage( self.tx, self.ty, self.tw, self.th, renderTarget )
        end
    end
    
    for _, child in ipairs( self.items ) do
        child:draw()
    end
end

function UIRenderTarget:update()
    UIDescriptor.update( self )

    if self.targetCanvas then
        self.targetCanvas:update()
    end

    if self._rt then
        destroyElement( self._rt )
    end

    self._rt = dxCreateRenderTarget( self.tw, self.th, true )
    if self._rt then
        if self.shader then
            dxSetShaderValue( self.shader, "Tex0", self._rt )
        end
    else
        outputDebugString( "При создании RT произошла ошибка", 2 )
    end
end

function UIRenderTarget:onCursorMove( ax, ay )
    UIDescriptor.onCursorMove( self, ax, ay )

    local targetCanvas = self.targetCanvas

    if self.selected and targetCanvas then
        local frx = ax - self.tx
        local fry = ay - self.ty

        targetCanvas:onCursorMove( frx, fry )
    end
end

function UIRenderTarget:onCursorClick( btn, state, ax, ay )
    UIDescriptor.onCursorClick( self, btn, state, ax, ay )

    if self.selected and self.targetCanvas then
        local frx = ax - self.tx
        local fry = ay - self.ty

        self.targetCanvas:onCursorClick( btn, state, frx, fry )
    end
end

function UIRenderTarget:setTargetCanvas( targetCanvas )
    self.targetCanvas = targetCanvas

    targetCanvas:update()
end

function UIRenderTarget:setShader( shader )
    self.shader = shader

    if self._rt then
        dxSetShaderValue( shader, "Tex0", self._rt )
    end
end

--[[
    UIScrollPane
]]
UIScrollPane = {
    typeName = "scrollpane",
    noticeable = true
}
UIScrollPaneMT = {
    __index = UIScrollPane
}
setmetatable( UIScrollPane, UIDescriptorMT )

function UIScrollPane:create( name, x, y, width, height )
    local frame = UIDescriptor:create( name, x, y, width, height )
    frame._rt = false

    return setmetatable( frame, UIScrollPaneMT )
end

function UIScrollPane:destroy()
    if self._rt then
        destroyElement( self._rt )
    end

    UIDescriptor.destroy( self )
end

function UIScrollPane:load( xml )
    UIDescriptor.load( self, xml )
end

function UIScrollPane:save( xml )
    UIDescriptor.save( self, xml )
end

function UIScrollPane:draw()
    if not self.visible then
        return
    end

    local renderTarget = self._rt

    if renderTarget then
        dxSetRenderTarget( renderTarget, true )
        for _, child in ipairs( self.items ) do
            child:draw()
        end
        dxSetRenderTarget()

        dxDrawImage( self.tx, self.ty, self.tw, self.th, renderTarget )
    end
end

function UIScrollPane:forward()
    self:update()

    local tx = self.tx
    local ty = self.ty

    self.tx = 0
    self.ty = 0

    for _, child in ipairs( self.items ) do
        child:forward()
    end

    self.tx = tx
    self.ty = ty
end

function UIScrollPane:update()
    UIDescriptor.update( self )

    if self._rt then
        destroyElement( self._rt )
    end

    self._rt = dxCreateRenderTarget( self.tw, self.th, true )
    if not self._rt then
        outputDebugString( "При создании RT произошла ошибка", 2 )
    end
end

function UIScrollPane:onCursorMove( ax, ay )
    if not self.canvas.focusLock then
        self.selected = false
    end

    if self.visible and isPointInRect( ax, ay, self.tx, self.ty, self.tw, self.th ) then
        if not self.canvas.focusLock then
            self.selected = true
            self.canvas.focused = self
        end

        local frx = ax - self.tx
        local fry = ay - self.ty

        for _, child in ipairs( self.items ) do
            child:onCursorMove( frx, fry )
        end
    end
end

function UIScrollPane:onCursorClick( btn, state, ax, ay )
    local frx = ax - self.tx
    local fry = ay - self.ty

    UIDescriptor.onCursorClick( self, btn, state, frx, fry )
end

--[[
    UIButton
]]
UIButton = {
    typeName = "button",
    inhibitPropagation = true
}
UIButtonMT = {
    __index = UIButton
}
setmetatable( UIButton, UIDescriptorMT )

UIBTN_DEFAULT = 1
UIBTN_SELECTED = 2
UIBTN_CLICKED = 3

function UIButton:create( name, x, y, width, height )
    local frame = UIDescriptor:create( name, x, y, width, height )
    frame.tex = nil
    frame.toggled = false
    frame.sections = {

    }
    frame.stateIdx = UIBTN_DEFAULT

    return setmetatable( frame, UIButtonMT )
end

function UIButton:load( xml )
    local textureName = xmlNodeGetAttribute( xml, "texture" )
    if textureName then
        self:setTexture( textureName )
    end

    self.toggled = xmlNodeGetAttribute( xml, "toggled" ) == "true"
    if self.toggled then
        self.stateIdx = xmlNodeGetAttribute( xml, "selected" ) == "true" and UIBTN_CLICKED or UIBTN_DEFAULT
    end

    local sectionsNode = xmlFindChild( xml, "sections", 0 )
    if sectionsNode then
        local defaultName = xmlNodeGetAttribute( sectionsNode, "default" )
        if defaultName then
            local section = xrTextureSections[ defaultName ]
            if section then
                self.sections[ UIBTN_DEFAULT ] = section
            else
                outputDebugString( "Cекции " .. defaultName .. " не существует!", 2 )
            end
        end

        local selectedName = xmlNodeGetAttribute( sectionsNode, "selected" )
        if selectedName then
            local section = xrTextureSections[ selectedName ]
            if section then
                self.sections[ UIBTN_SELECTED ] = section
            else
                outputDebugString( "Cекции " .. selectedName .. " не существует!", 2 )
            end
        end

        local clickedName = xmlNodeGetAttribute( sectionsNode, "clicked" )
        if clickedName then
            local section = xrTextureSections[ clickedName ]
            if section then
                self.sections[ UIBTN_CLICKED ] = section
            else
                outputDebugString( "Cекции " .. clickedName .. " не существует!", 2 )
            end
        end
    end   

    UIDescriptor.load( self, xml )
end

function UIButton:save( xml )
    if self.tex then
        xmlNodeSetAttribute( xml, "texture", tostring( self.texName ) )
    end

    xmlNodeSetAttribute( xml, "toggled", self.toggled == true and "true" or "false" )
    if self.toggled then
        xmlNodeSetAttribute( xml, "selected", self.stateIdx == UIBTN_CLICKED and "true" or "false" )
    end

    local sectionsNode = xmlCreateChild( xml, "sections" )
    if self.sections[ UIBTN_DEFAULT ] then
        xmlNodeSetAttribute( sectionsNode, "default", tostring( self.sections[ UIBTN_DEFAULT ].id ) )
    end
    if self.sections[ UIBTN_SELECTED ] then
        xmlNodeSetAttribute( sectionsNode, "selected", tostring( self.sections[ UIBTN_SELECTED ].id ) )
    end
    if self.sections[ UIBTN_CLICKED ] then
        xmlNodeSetAttribute( sectionsNode, "clicked", tostring( self.sections[ UIBTN_CLICKED ].id ) )
    end

    UIDescriptor.save( self, xml )
end

function UIButton:draw()
    if not self.visible then
        return
    end

    local color = tocolor( 255, 255, 255 )

    local section = self.sections[ self.stateIdx ] or self.sections[ UIBTN_DEFAULT ]
    if self.tex and section then
        section:draw( self.tex, self.tx, self.ty, self.tw, self.th, 0, 0, 0, color )
    end    

    for _, child in ipairs( self.items ) do
        child:draw()
    end
end

function UIButton:onVisibleChange( visible )
    if not self.toggled then
        self.stateIdx = UIBTN_DEFAULT
    end
end

function UIButton:onCursorEnter( ax, ay )
    if not self.toggled then
        self.stateIdx = UIBTN_SELECTED
    end
end

function UIButton:onCursorExit( ax, ay )
    if not self.toggled then
        self.stateIdx = UIBTN_DEFAULT
    end
end

function UIButton:onCursorClick( btn, state, ax, ay )
    UIDescriptor.onCursorClick( self, btn, state, ax, ay )

    if state == "down" then
        if self.toggled then
            self.stateIdx = self.stateIdx == UIBTN_CLICKED and UIBTN_DEFAULT or UIBTN_CLICKED
        else
            self.stateIdx = UIBTN_CLICKED
        end

        if type( self.handlerFn ) == "function" then
            local prevSourceValue = _G[ "source" ]

            _G[ "source" ] = self
            self.handlerFn( unpack( self.handlerArgs ) )
            _G[ "source" ] = prevSourceValue
        end
    elseif not self.toggled then
        self.stateIdx = UIBTN_SELECTED
    end    
end

function UIButton:addHandler( fn, ... )
    self.handlerFn = fn
    self.handlerArgs = { ... }
end

function UIButton:setTexture( textureName )
    local tex = exports.sp_assets:xrLoadAsset( textureName )
    if tex then
        self.tex = tex
        self.texName = textureName -- Для сохранения
    else
        outputDebugString( "Текстуры с именем " .. tostring( textureName ) .. " не существует!", 2 )
    end
end

function UIButton:setTextureSection( stateIdx, sectionName )
    local section = xrTextureSections[ sectionName ]
    if section then
        self.sections[ stateIdx ] = section
    else
        outputDebugString( "Cекции " .. sectionName .. " не существует!", 2 )
    end
end

function UIButton:setToggled( toggled )
    self.toggled = toggled
end

--[[
    UIEditField
]]
UIEditField = {
    typeName = "editfield"
}
UIEditFieldMT = {
    __index = UIEditField
}
setmetatable( UIEditField, UIDescriptorMT )

local _textMask = function( text )
	local result = ""
	for i = 1, utfLen( text ) do
		result = result .. "*"
	end
	return result
end

function UIEditField:create( name, x, y, width, height )
    local frame = UIDescriptor:create( name, x, y, width, height )
    frame.text = ""
    frame.maxLength = 10
    frame.color = tocolor( 255, 255, 255 )
    frame.scale = 1
    frame.font = nil
    frame.fontName = "default"
    frame.masked = false
    frame.memo = false

    return setmetatable( frame, UIEditFieldMT )
end

function UIEditField:load( xml )
    local fontName = xmlNodeGetAttribute( xml, "font" )
    if fontName then
        self:setFont( fontName )
    end

    local text = xmlNodeGetAttribute( xml, "text" )
    if text then
        self:setText( text )
    end

    local scale = tonumber( xmlNodeGetAttribute( xml, "scale" ) )
    if scale then
        self:setScale( scale )
    end

    self:setMasked( xmlNodeGetAttribute( xml, "masked" ) == "true" )
    self:setMemo( xmlNodeGetAttribute( xml, "memo" ) == "true" )

    local length = tonumber( xmlNodeGetAttribute( xml, "length" ) )
    if length then
        self:setMaxLength( length )
    end

    UIDescriptor.load( self, xml )
end

function UIEditField:save( xml )
    xmlNodeSetAttribute( xml, "font", tostring( self.fontName ) )
    xmlNodeSetAttribute( xml, "text", tostring( self.text ) )
    xmlNodeSetAttribute( xml, "scale", tonumber( self.scale ) or 1 )
    xmlNodeSetAttribute( xml, "masked", self.masked == true and "true" or "false" )
    xmlNodeSetAttribute( xml, "memo", self.memo == true and "true" or "false" )
    xmlNodeSetAttribute( xml, "length", tostring( self.maxLength ) )

    UIDescriptor.save( self, xml )
end

function UIEditField:draw()
    if not self.visible then
        return
    end

    local font = self.font
    if not isElement( font ) then
        font = self.fontName
        if type( font ) ~= "string" then
            font = "default"
        end
    end

    local text = tostring( self.text )
    if self.masked then
        text = _textMask( text )
    end
    if self == self.canvas.inputFrame and getTickCount ( ) % 2000 >= 1000 then
		text = text .. "|"
	end

    dxDrawText( 
        tostring( text ), 
        self.tx, self.ty, 
        self.tx + self.tw, self.ty + self.th, 
        self.color, self.scale, 
        font, "left", self.memo == true and "top" or "center", true, self.memo == true
    )  

    for _, child in ipairs( self.items ) do
        child:draw()
    end
end

function UIEditField:onCursorEnter( ax, ay )   
end

function UIEditField:onCursorExit( ax, ay )    
end

function UIEditField:onCursorClick( btn, state, ax, ay )
    UIDescriptor.onCursorClick( self, btn, state, ax, ay )

    if state == "down" then
        self.canvas:setInputFrame( self )
    end    
end

function UIEditField:setMasked( masked )
    self.masked = masked == true
end

function UIEditField:setMemo( memo )
    self.memo = memo == true
end

function UIEditField:setText( text )
    if utfLen ( text ) > self.maxLength then
		text = utfSub ( text, 1, self.maxLength )
    end

	self.text = text
end

function UIEditField:setScale( scale )
    self.scale = tonumber( scale )
end

function UIEditField:setMaxLength( length )
    self.maxLength = math.min( length, 100 )
end

function UIEditField:setFont( fontName )
    if defaultFontsLookup[ fontName ] then
        self.font = nil
        self.fontName = fontName

        return
    end

    local font = exports.sp_assets:xrLoadAsset( fontName )
    if not font then
        outputDebugString( "Шрифта с именем " .. tostring( fontName ) .. " не существует!" )

        return
    end

    self.font = font
    self.fontName = fontName
end

--[[
    UIScroller
]]
UIScrollBar = {
    typeName = "scrollbar"
}
UIScrollBarMT = {
    __index = UIScrollBar
}
setmetatable( UIScrollBar, UIDescriptorMT )

function UIScrollBar:create( name, x, y, width, height )
    local frame = UIDescriptor:create( name, x, y, width, height )
    frame.clicked = false
    frame.scale = 0.2
    frame.clickedBiasX = 0
    frame.clickedBiasY = 0
    frame.horizontal = false

    return setmetatable( frame, UIScrollBarMT )
end

function UIScrollBar:forward()
    UIDescriptor.forward( self )

    local firstChild = self.items[ 1 ]
    if firstChild then
        firstChild:setSize( firstChild.originWidth, self.th * self.scale )
        firstChild:setPosition( 
            math.clamp( 0, self.tw - firstChild.tw, firstChild.originX ), 
            math.clamp( 0, self.th - firstChild.th, firstChild.originY ) 
        )
        firstChild:update()
    end
end

function UIScrollBar:onCursorMove( ax, ay )
    UIDescriptor.onCursorMove( self, ax, ay )

    local firstChild = self.items[ 1 ]
    if firstChild and firstChild.selected and self.clicked then
        local x = firstChild.originX
        local y = firstChild.originY

        if self.horizontal then
            x = ( ax + self.clickedBiasX ) - self.tx
        else
            y = ( ay + self.clickedBiasY ) - self.ty
        end

        firstChild:setPosition( 
            math.clamp( 0, self.tw - firstChild.tw, x ),
            math.clamp( 0, self.th - firstChild.th, y ) 
        )
        firstChild:update()
    end
end

function UIScrollBar:onCursorClick( btn, state, ax, ay )
    UIDescriptor.onCursorClick( self, btn, state, ax, ay )

    self.clicked = self.selected and state == "down"

    local firstChild = self.items[ 1 ]
    if firstChild then
        self.clickedBiasX = firstChild.tx - ax
        self.clickedBiasY = firstChild.ty - ay
    end
end

function UIScrollBar:addValue( delta )
    local x = firstChild.originX
    local y = firstChild.originY

    if self.horizontal then
        x = x + delta
    else
        y = y + delta
    end

    firstChild:setPosition( 
        math.clamp( 0, self.tw - firstChild.tw, x ),
        math.clamp( 0, self.th - firstChild.th, y ) 
    )
    firstChild:update()
end

function UIScrollBar:setScale( scale )
    self.scale = scale

    local firstChild = self.items[ 1 ]
    if firstChild then
        firstChild:setSize( firstChild.tw, self.th * scale )
        firstChild:setPosition( 
            math.clamp( 0, self.tw - firstChild.tw, firstChild.originX ), 
            math.clamp( 0, self.th - firstChild.th, firstChild.originY ) 
        )
        firstChild:update()
    end
end

--[[
    UIProgressBar
]]
UIProgressBar = {
    typeName = "progress"
}
UIProgressBarMT = {
    __index = UIProgressBar
}
setmetatable( UIProgressBar, UIDescriptorMT )

function UIProgressBar:create( name, x, y, width, height )
    local frame = UIDescriptor:create( name, x, y, width, height )
    frame.pos = 1
    frame.tex = nil
    frame.texSection = nil
    frame.texName = ""

    return setmetatable( frame, UIProgressBarMT )
end

function UIProgressBar:load( xml )
    local textureName = xmlNodeGetAttribute( xml, "texture" )
    if textureName then
        self:setTexture( textureName )
    end

    local sectionName = xmlNodeGetAttribute( xml, "section" )
    if sectionName then
        self:setTextureSection( sectionName )
    end

    local pos = tonumber( xmlNodeGetAttribute( xml, "pos" ) ) 
    if pos then
        self.pos = pos
    end

    UIDescriptor.load( self, xml )
end

function UIProgressBar:save( xml )
    if self.tex then
        xmlNodeSetAttribute( xml, "texture", tostring( self.texName ) )
    end
    if self.texSection then
        xmlNodeSetAttribute( xml, "section", tostring( self.texSection.id ) )
    end
    xmlNodeSetAttribute( xml, "pos", tonumber( self.pos ) or 1 )

    UIDescriptor.save( self, xml )
end

function UIProgressBar:draw()
    if not self.visible then
        return
    end

    local texture = self.tex
    if texture then
        local textureSection = self.texSection
        if textureSection then
            textureSection:drawProgress( texture, self.tx, self.ty, self.tw, self.th, self.pos, 1 )
        end
    end
    
    for _, child in ipairs( self.items ) do
        child:draw()
    end
end

function UIProgressBar:setProgress( pos )
    self.pos = math.min( math.max( pos, 0 ), 1 )
end

function UIProgressBar:setTexture( textureName )
    local tex = exports.sp_assets:xrLoadAsset( textureName )
    if tex then
        self.tex = tex
        self.texName = textureName -- Для сохранения
    else
        outputDebugString( "Текстуры с именем " .. tostring( textureName ) .. " не существует!", 2 )
    end
end

function UIProgressBar:setTextureSection( sectionName )
    local section = xrTextureSections[ sectionName ]
    if section then
        self.texSection = section
    else
        outputDebugString( "Текстурной секции " .. sectionName .. " не существует!", 2 )
    end
end


--[[
    UIText
]]
UIText = {
    typeName = "text"
}
UITextMT = {
    __index = UIText
}
setmetatable( UIText, UIDescriptorMT )

function UIText:create( name, x, y, width, height )
    local frame = UIDescriptor:create( name, x, y, width, height )
    frame.text = ""
    frame.font = nil
    frame.fontName = "default"
    frame.scale = 1
    frame.alignX = "left"
    frame.alignY = "top"
    frame.clip = false
    frame.wordBreak = false
    frame.color = { 255, 255, 255 }
    frame.colorInt = tocolor( 255, 255, 255 )

    return setmetatable( frame, UITextMT )
end

function UIText:load( xml )
    local fontName = xmlNodeGetAttribute( xml, "font" )
    if fontName then
        self:setFont( fontName )
    end

    local text = xmlNodeGetAttribute( xml, "text" )
    if text then
        self:setText( text )
    end

    local alignX = xmlNodeGetAttribute( xml, "alignX" )
    if alignX == "left" or alignX == "center" or alignX == "right" then
        self.alignX = alignX
    end

    local alignY = xmlNodeGetAttribute( xml, "alignY" )
    if alignY == "top" or alignY == "center" or alignY == "bottom" then
        self.alignY = alignY
    end

    local scale = tonumber( xmlNodeGetAttribute( xml, "scale" ) )
    if scale then
        self:setScale( scale )
    end

    local color = xmlNodeGetColor( xml, "color", { 255, 255, 255 } )
    if color then
        self.color = color
        self.colorInt = tocolor( unpack( color ) )
    end

    self.clip = xmlNodeGetAttribute( xml, "clip" ) == "true"
    self.wordBreak = xmlNodeGetAttribute( xml, "wordBreak" ) == "true"

    UIDescriptor.load( self, xml )
end

function UIText:save( xml )
    xmlNodeSetAttribute( xml, "font", tostring( self.fontName ) )
    xmlNodeSetAttribute( xml, "text", tostring( self.text ) )
    xmlNodeSetAttribute( xml, "alignX", self.alignX or "left" )
    xmlNodeSetAttribute( xml, "alignY", self.alignY or "top" )
    xmlNodeSetAttribute( xml, "scale", tonumber( self.scale ) or 1 )
    xmlNodeSetAttribute( xml, "clip", self.clip == true and "true" or "false" )
    xmlNodeSetAttribute( xml, "wordBreak", self.wordBreak == true and "true" or "false" )
    xmlNodeSetAttribute( xml, "color", self.color[ 1 ] .. " " .. self.color[ 2 ] .. " " .. self.color[ 3 ] )

    UIDescriptor.save( self, xml )
end

local function getRealTextHeight( text, scale, font, width )
	local words = split( text, 32 ) -- space
	local fontHeight = dxGetFontHeight( scale, font )
	local spaceWidth = dxGetTextWidth( " ", scale, font )

	local lineWidth = 0
	local height = fontHeight

	for _, word in ipairs( words ) do
		lineWidth = lineWidth + spaceWidth
		if lineWidth >= width then
			height = height + fontHeight
			lineWidth = spaceWidth
		end

		local wordWidth = dxGetTextWidth( word, scale, font )
		lineWidth = lineWidth + wordWidth
		if lineWidth >= width then
			height = height + fontHeight
			lineWidth = wordWidth
		end
	end
	
	return height
end

function UIText:update()
    UIDescriptor.update( self )

    if self.wordBreak then
        local font = self.font
        if not isElement( font ) then
            font = self.fontName
            if type( font ) ~= "string" then
                font = "default"
            end
        end

        local textHeight = getRealTextHeight( self.text, self.scale, font, self.tw )
        self.th = textHeight
    end
end

function UIText:draw()
    if not self.visible then
        return
    end

    local font = self.font
    if not isElement( font ) then
        font = self.fontName
        if type( font ) ~= "string" then
            font = "default"
        end
    end

    dxDrawText( 
        tostring( self.text ), 
        self.tx, self.ty, 
        self.tx + self.tw, self.ty + self.th, 
        self.colorInt, self.scale, 
        font, self.alignX, self.alignY, self.clip, self.wordBreak
    )    
    
    for _, child in ipairs( self.items ) do
        child:draw()
    end
end

function UIText:setText( text )
    self.text = text
end

function UIText:setColor( r, g, b )
    self.color = { r, g, b }
    self.colorInt = tocolor( r, g, b )
end

function UIText:setAlign( alignX, alignY )
    self.alignX = alignX
    self.alignY = alignY
end

function UIText:setScale( scale )
    self.scale = tonumber( scale ) or 1
end

function UIText:setFont( fontName )
    if defaultFontsLookup[ fontName ] then
        self.font = nil
        self.fontName = fontName

        return
    end

    local font = exports.sp_assets:xrLoadAsset( fontName )
    if not font then
        outputDebugString( "Шрифта с именем " .. tostring( fontName ) .. " не существует!" )

        return
    end

    self.font = font
    self.fontName = fontName
end

function UIText:setWordClip( clip )
    self.clip = clip == true
end

function UIText:setWordBreak( wordBreak )
    self.wordBreak = wordBreak == true
end

--[[
    UICanvas
]]
UICanvas = {

}
UICanvasMT = {
    __index = UICanvas
}

function UICanvas:destroy()
    if self.frame then
        self.frame:destroy()
    end
    self.focused = nil
end

function UICanvas:draw()
    if self.frame then
        self.frame:draw()
    end
end

function UICanvas:update()
    if self.frame then
        self.frame:forward()
    end
end

function UICanvas:getFrame( key, recursive )
    if self.frame then
        return self.frame:getFrame( key, recursive )
    end

    return false
end

function UICanvas:onFrameRemoved( frame )
    if frame == self.frame then
        self.frame = nil
    end

    -- Если удаляемый фрейм выделен - убираем выделение
    if frame == self.focused then
        frame:onCursorExit( ax, ay )
        self.focused = nil
    end

    -- Если удаляемый фрейм выделен - убираем выделение
    if frame == self.inputFrame then
        self.inputFrame = nil
    end
end

function UICanvas:insertChild( frame )
    if self.frame then
        return self.frame:insertChild( frame )
    end
end

function UICanvas:setInputFrame( frame )
    self.inputFrame = frame
end

function UICanvas:setPosition( screenX, screenY )
    self.screenX = screenX
    self.screenY = screenY
end

function UICanvas:setSize( screenWidth, screenHeight )
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
end

function UICanvas:load( xml )
    if self.frame then
        self.frame:destroy()
        self.frame = nil
    end

    self.frame = self:insert( xml )
end

function UICanvas:insert( xml, parentFrame )
    local xmlnode = xmlFindChild( xml, "frame", 0 )
    if xmlnode then
        local frameType = xmlNodeGetAttribute( xmlnode, "type" )
        local frame = UIFrameFactory:create( frameType )      
        if frame then
            frame.canvas = self
            if parentFrame then
                frame.parent = parentFrame
            end

            frame:load( xmlnode )

            if parentFrame then
                parentFrame:insertChild( frame )
            end        
                    
            return frame
        end
    end

    outputDebugString( "XML узел не содержит ни одного фрейма", 2 )
    return false
end

function UICanvas:save( xml )
    if self.frame then
        local xmlnode = xmlCreateChild( xml, "frame" )
        self.frame:save( xmlnode )
    end
end

function UICanvas:onCursorMove( ax, ay )
    local prevFocus = self.focused
    if not self.focusLock then
        self.focused = nil
    end

    if self.frame then
        self.frame:onCursorMove( ax, ay )

        if self.focused ~= prevFocus and not self.focusLock then
            if prevFocus then
                prevFocus:onCursorExit( ax, ay )
            end

            if self.focused then
                self.focused:onCursorEnter( ax, ay )
            end
        end
    end
end

function UICanvas:onCursorClick( btn, state, ax, ay )
    self.focusLock = state == "down"
    if state == "down" then
        self.inputFrame = nil
    end

    if self.frame then 
        self.frame:onCursorClick( btn, state, ax, ay )
    end
end

function UICanvas:onCharacter( char )
    local frame = self.inputFrame
    if frame then
        frame:setText( frame.text .. char )
    end
end

function UICanvas:onKey( key, pressed )
    if not pressed then
        return
    end 
		
    if key == "backspace" then
        local frame = self.inputFrame
        if frame then
            frame:setText ( 
                utfSub( frame.text, 1, utfLen ( frame.text ) - 1 )
            )
        end
    end
end

function xrCreateUICanvas( screenX, screenY, screenWidth, screenHeight )  
    local canvas = {
        screenX = tonumber( screenX ) or 0,
        screenY = tonumber( screenY ) or 0,
        screenWidth = tonumber( screenWidth ) or 1024,
        screenHeight = tonumber( screenHeight ) or 768,
        focused = nil,
        inputFrame = nil
    }

    local frame = UIDescriptor:create( "Canvas", screenX, screenY, screenWidth, screenHeight )
    frame.canvas = canvas

    canvas.frame = frame

    return setmetatable( canvas, UICanvasMT )
end