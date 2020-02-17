--[[
    Enum
]]
local _enumName = ""
local function _enumNew( tbl )
    for i, value in ipairs( tbl ) do
        tbl[ value ] = i
        _G[ value ] = i
    end

    _G[ _enumName ] = tbl
end
function enum( name )
    _enumName = name
    return _enumNew
end

function _hashFn( str )
    local result = 0
    for i = 1, string.len( str ) do
        local byte = string.byte( str, i )
        result = byte + bitLShift( result, 6 ) + bitLShift( result, 16 ) - result
    end
    return result
end

local _lastValues = setmetatable( {}, { __mode = "kv" } )

local IDGenerator = {
    allocate = function( self )
        local last = _lastValues[ self ]
        if type( last ) == "number" then
            last = last + 1
        else
            local latestId = 0
            for i, v in pairs( self ) do
                if type( i ) == "number" then 
                    latestId = math.max( i, latestId )
                end
            end
            last = latestId + 1
        end

        _lastValues[ self ] = last
        return last
    end,
    push = function( self, value )
        local id = self:allocate()
        self[ id ] = value

        return id
    end
}
local IDGeneratorMT = {  
    __index = IDGenerator
}

function xrMakeIDTable()
    return setmetatable( {}, IDGeneratorMT )
end

function table.copy(tab, recursive)
    local ret = {}
    for key, value in pairs(tab) do
        if (type(value) == "table") and recursive then ret[key] = table.copy(value)
        else ret[key] = value end
    end
    return ret
end

function table.find( tbl, value )
    for i, v in ipairs( tbl ) do
        if v == value then
            return i
        end
    end
end

function table.insertIfNotExists( tbl, value )
    for i, v in ipairs( tbl ) do
        if v == value then
            return
        end
    end

    local i = #tbl + 1
    tbl[ i ] = value
    return i
end

function table.removeValue( tbl, value )
    for i, v in ipairs( tbl ) do
        if v == value then
            table.remove( tbl, i )
            return i
        end
    end
end

function math.clamp( min, max, value )
    return math.max( math.min( value, max ), min )
end

function math.interpolate( from, to, t )
    t = math.clamp( 0, 1, t )
    return to * t + from * ( 1 - t )
end

function math.round( num, numDecimalPlaces )
    local mult = 10 ^ ( numDecimalPlaces or 0 )
    return math.floor( num * mult + 0.5 ) / mult
end

function RGBToHex(red, green, blue, alpha)
	
	-- Make sure RGB values passed to this function are correct
	if( ( red < 0 or red > 255 or green < 0 or green > 255 or blue < 0 or blue > 255 ) or ( alpha and ( alpha < 0 or alpha > 255 ) ) ) then
		return nil
	end

	-- Alpha check
	if alpha then
		return string.format("#%.2X%.2X%.2X%.2X", red, green, blue, alpha)
	else
		return string.format("#%.2X%.2X%.2X", red, green, blue)
	end

end

--[[
    ElementTypeWatcher
]]
local xrWatchTypes = {}

local function _onElementCreated()
    local watcher = xrWatchTypes[ getElementType( source ) ]
    if watcher then
        if table.insertIfNotExists( watcher.elements, source ) then
            watcher.onCreateFn( source )
        end
    end
end

local function _onElementDestroyed()
    local watcher = xrWatchTypes[ getElementType( source ) ]
    if watcher then
        if table.removeValue( watcher.elements, source ) then
            watcher.onDestroyFn( source )
        end
    end
end

function xrCreateTypeWatcher( elementType, streamedIn, onCreateFn, onDestroyFn )
    if xrWatchTypes[ elementType ] then
        return
    end
    
    if elementType == "player" then
        addEventHandler( "onClientPlayerJoin", root, _onElementCreated )
        addEventHandler( "onClientPlayerQuit", root, _onElementDestroyed )
    else
        -- TODO
    end

    if streamedIn then
        addEventHandler( "onClientElementStreamIn", root, _onElementCreated )
        addEventHandler( "onClientElementStreamOut", root, _onElementDestroyed )
    end   

    local elements = {}
    for i, element in ipairs( getElementsByType( elementType, root, streamedIn ) ) do
        table.insert( elements, element )
        onCreateFn( element )
    end

    xrWatchTypes[ elementType ] = {
        onCreateFn = onCreateFn,
        onDestroyFn = onDestroyFn,
        elements = elements
    }
end

function restoreFromJSON( tbl )
    local result = {}

    if type( tbl ) == "table" then
        local function _cast( v )
            local casted = tonumber( v )
            if casted then
                return casted
            end
            if casted == "true" then
                return true
            end
            if casted == "false" then
                return false
            end
            return tostring( v )
        end

        for i, v in pairs( tbl ) do
            local icast = _cast( i )
            local vcast
            if type( v ) == "table" then
                vcast = restoreFromJSON( v )
            else
                vcast = _cast( v )
            end

            result[ icast ] = vcast
        end
    end

    return result
end