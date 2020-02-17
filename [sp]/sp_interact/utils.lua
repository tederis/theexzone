local function _parse( str )
	if type( str ) ~= "string" then
		return str
	end

	if str:sub( 1, 1 ) == '#' then
		local endPos = str:find ( '#', 2 )
        if endPos then
			return _hashFn( str:sub ( 2, endPos - 1 ) )
		else
			outputDebugString ( "Обнаружена незавершенная хэш-строка: " .. str, 2 )
			return _hashFn( str:sub ( 2, str:len ( ) ) )
        end
	end
	
	return str
end

function isPointInRect( ax, ay, wx, wy, ww, wh )
    return ax >= wx and ax <= wx + ww and ay >= wy and ay <= wy + wh
end

--[[
    xrRadialMenu
]]
local ENTRY_HEIGHT = 20
local ENTRY_GAP = 5

xrRadialMenu = {
    visible = false,
    variables = {}
}

function xrRadialMenu:setVar( key, value )
    self.variables[ key ] = value
end

function xrRadialMenu:load( xml )
    local rootEntry = {
        name = "Действия",
        children = {},
        state = true
    }

    for _, node in ipairs( xmlNodeGetChildren( xml ) ) do
        local nodeEntry = self:loadEntry( node )
        if nodeEntry then
            nodeEntry.parent = rootEntry
            table.insert( rootEntry.children, nodeEntry )
        end
    end

    self.root = rootEntry
end

function xrRadialMenu:loadEntry( node )
    local nodeName = xmlNodeGetAttribute( node, "name" )
    local fnName = xmlNodeGetAttribute( node, "fn" )
    local fnArgs = xmlNodeGetAttribute( node, "args" )
    local cooldown = tonumber( xmlNodeGetAttribute( node, "cooldown" ) )

    local entry = {
        name = nodeName,
        children = {},
        conditions = {},
        state = false,
        counter = 0
    }

    local fn = _G[ fnName ]
    if type( fn ) == "function" then
        entry.fn = fn
        entry.fnArgs = _parse( fnArgs )
    end

    if cooldown then
        entry.cooldown = cooldown
    end

    for _, child in ipairs( xmlNodeGetChildren( node ) ) do
        local nodeName = xmlNodeGetName( child )
        if nodeName == "entry" then
            local childEntry = self:loadEntry( child )
            if childEntry then
                childEntry.parent = entry
                table.insert( entry.children, childEntry )
            end
        elseif nodeName == "condition" then
            local name = xmlNodeGetAttribute( child, "name" )
            local inverse = xmlNodeGetAttribute( child, "inverse" ) == "true"
            local equal = xmlNodeGetAttribute( child, "equal" )

            local condition = {
                name = name,
                inverse = inverse
            }

            if equal then
                condition.equal = _parse( equal )
            end

            table.insert( entry.conditions, condition )
        end
    end

    return entry
end

function xrRadialMenu:resolveEntry( entry )
    local vars = self.variables
    
    if entry.cooldown and entry.lastTime and getTickCount() - entry.lastTime < entry.cooldown*60000 then
        return false
    end

    for _, condition in ipairs( entry.conditions ) do
        local value = vars[ condition.name ]
        if condition.equal then
            value = value == condition.equal
        else
            value = value ~= false and value ~= nil
        end
        if condition.inverse then
            value = not value
        end

        if not value then
            return false
        end
    end

    local counter = 0

    for _, child in ipairs( entry.children ) do
        if self:resolveEntry( child ) then
            counter = counter + 1
        end
    end

    return counter > 0 or #entry.children == 0
end

function xrRadialMenu:traverse( entry, output )
    for _, childEntry in ipairs( entry.children ) do
        if self:resolveEntry( childEntry ) then
            table.insert( output, childEntry )
        end
    end
end

function xrRadialMenu:show()
    if self.visible then
        return
    end

    if self:setEntry( self.root ) then
        addEventHandler( "onClientRender", root, xrRadialMenu.draw, false )
        addEventHandler( "onClientCursorMove", root, xrRadialMenu.onCursorMove, false )
        addEventHandler( "onClientClick", root, xrRadialMenu.onCursorClick, false )

        showCursor( true )

        self.visible = true
    end
end

function xrRadialMenu:hide()
    if not self.visible then
        return
    end

    removeEventHandler( "onClientRender", root, xrRadialMenu.draw )
    removeEventHandler( "onClientCursorMove", root, xrRadialMenu.onCursorMove )
    removeEventHandler( "onClientClick", root, xrRadialMenu.onCursorClick )

    showCursor( false )

    self.current = nil
    self.frames = nil
    self.visible = false
end

function xrRadialMenu:setEntry( entry )
    local frames = {

    }
    self:traverse( entry, frames )

    if #frames > 0 then        
        self.selectedItem = nil
        self.frames = frames
        self:update()

        if entry.parent then
            local sw, sh = guiGetScreenSize()
            local cx, cy = sw / 2, sh / 2
            local textWidth = dxGetTextWidth( entry.parent.name )

            entry.parent._x = cx - textWidth/2 - ENTRY_GAP
            entry.parent._y = cy - ENTRY_HEIGHT/2
            entry.parent._w = textWidth + ENTRY_GAP*2
            entry.parent._h = ENTRY_HEIGHT
            table.insert( frames, entry.parent )
        end

        return true
    end

    return false
end

function xrRadialMenu:update()
    local frames = self.frames
    if not frames then
        return
    end

    local sw, sh = guiGetScreenSize()
    local cx, cy = sw / 2, sh / 2

    local radius = 100

    local stepAngle = math.pi*2 / #frames
    local angle = 0
    for _, child in ipairs( frames ) do
        local ax = radius * math.cos( angle )
        local ay = radius * math.sin( angle )

        local textWidth = dxGetTextWidth( child.name )

        if ax > 0 then
            local x = cx + ax
            local y = cy + ay - ENTRY_HEIGHT/2
            local width = textWidth + ENTRY_GAP*2
            local height = ENTRY_HEIGHT

            child._x = x
            child._y = y
            child._w = width
            child._h = height
        else
            local x = cx + ax - textWidth - ENTRY_GAP*2
            local y = cy + ay - ENTRY_HEIGHT/2
            local width = textWidth + ENTRY_GAP*2
            local height = ENTRY_HEIGHT

            child._x = x
            child._y = y
            child._w = width
            child._h = height
        end

        angle = angle + stepAngle
    end
end

function xrRadialMenu.draw()
    local self = xrRadialMenu
    local frames = self.frames
    if not frames then
        return
    end

    --[[
        Рисуем детей
    ]]
    for _, child in ipairs( frames ) do
        dxDrawRectangle( child._x, child._y, child._w, child._h, self.selectedItem == child and tocolor( 205, 255, 255 ) or tocolor( 205, 205, 205 )  )
        dxDrawText( child.name, child._x, child._y, child._x + child._w, child._y + child._h, tocolor( 0, 0, 200 ), 1, "default", "center", center )
    end
end

function xrRadialMenu.onCursorMove( _, _, ax, ay )
    local self = xrRadialMenu
    local frames = self.frames
    if not frames then
        return
    end

    self.selectedItem = nil

    for _, child in ipairs( frames ) do
        if isPointInRect( ax, ay, child._x, child._y, child._w, child._h ) then
            self.selectedItem = child
        end
    end
end

function xrRadialMenu.onCursorClick( btn, state, ax, ay )
    local self = xrRadialMenu
    if not self.selectedItem or state ~= "down" then
        return
    end

    self.selectedItem.lastTime = getTickCount()

    if self:setEntry( self.selectedItem ) then
        
    elseif #self.selectedItem.children == 0 then
        if type( self.selectedItem.fn ) == "function" then
            self.selectedItem.fn( self.selectedItem.fnArgs )
        end

        self:hide()
    end
end