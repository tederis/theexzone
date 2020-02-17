g_ZoneHashes = {

}

Zone = {

}

ZONE_IDLE = 1 -- Состояние зоны, когда внутри нее нет активных объектов
ZONE_AWAKING = 2 -- Пробуждение зоны (объект попал в зону)
ZONE_BLOWOUT = 3 -- Выброс
ZONE_ACCUMULATE = 4 -- Накапливание энергии после выброса
ZONE_DISABLE = 5 -- Зона отключена

BLOWOUT_PARTICLE = 1
BLOWOUT_LIGHT = 2
BLOWOUT_SOUND = 3
BLOWOUT_AFFECT = 4

ZONE_CREATE = 1
ZONE_DESTROY = 2
ZONE_ART_SPAWN = 3
ZONE_ART_DESTROY = 4
ZONE_STATE_CHANGE = 5
ZONE_INIT = 6
ZONE_PURGE = 7
ZONE_OWNER = 8
ZONE_TAKING_TEAM = 9

ZA_ID = 1
ZA_TYPEHASH = 2
ZA_POS = 3
ZA_RADIUS = 4
ZA_COLSHAPE = 5
ZA_ARTS = 6
ZA_STATE = 7
ZA_OWNER = 8
ZA_STRENGTH = 9
ZA_TIMESTAMP = 10

function Zone:create()
    self.nodesInside = {}

    local function _onZoneHit( element, matchingDimension )
        local elementTypes = self.elementTypes
        if matchingDimension and elementTypes[ getElementType( element ) ] then
            table.insertIfNotExists( self.nodesInside, element )

            self:onHit( element )
        end
    end
    local function _onZoneLeave( element, matchingDimension )
        local elementTypes = self.elementTypes
        if matchingDimension and elementTypes[ getElementType( element ) ] then
            table.removeValue( self.nodesInside, element )

            self:onLeave( element )
        end
    end

    if self.section.col_shape == "circle" then
        self.col = createColCircle( self.pos, self.radius )
    else
        self.col = createColSphere( self.pos, self.radius )
    end
    setElementData( self.col, "znid", self.id, true )
    addEventHandler( "onColShapeHit", self.col, _onZoneHit, false )
    addEventHandler( "onColShapeLeave", self.col, _onZoneLeave, false )

    return true
end

function Zone:destroy()
    if isElement( self.col ) then
        destroyElement( self.col )
    end    
end

function Zone:read( data )

end

function Zone:write( out )
    out[ ZA_ID ] = self.id
    out[ ZA_TYPEHASH ] = self.typeHash
    local pos = self.pos
    out[ ZA_POS ] = { pos:getX(), pos:getY(), pos:getZ() }
    if isElement( self.col ) then
        out[ ZA_COLSHAPE ] = self.col
    end
    out[ ZA_RADIUS ] = self.radius
    out[ ZA_STRENGTH ] = self.strength
end

function Zone:onHit( element )
end

function Zone:onLeave( element )    
end

function Zone:getPower( dist, shapeRadius, relative )
    local section = self.section
    local power = 0

    local radius = shapeRadius*section.effective_radius    
    if radius > dist then
        local sqr = dist / radius
        power = 1 - section.attenuation*sqr*sqr
    end

    if relative then
        return math.max( power, 0 )
    else
        return math.max( power * self.strength, 0 )
    end
end

function Zone:isElementWithin( element )
    for _, el in ipairs( self.nodesInside ) do
        if el == element then
            return true
        end
    end
    return false
end

--[[
    ZoneRadiation
]]
ZoneRadiation = {
    -- Допустимые для зоны элементы
    elementTypes = {
        [ "player" ] = true
    }
}
setmetatable( ZoneRadiation, { __index = Zone } )

function ZoneRadiation:create( typeHash, position, id )
    if Zone.create( self, typeHash, position, id ) then            
        
        return true
    end

    return false
end

function ZoneRadiation:destroy()
    Zone.destroy( self )
end

function ZoneRadiation:write( out )
    Zone.write( self, out )
end

function ZoneRadiation:onHit( element )
    
end

function ZoneRadiation:onLeave( element )
    
end


function ZoneRadiation:update( dt )  
end

--[[
    ZoneCampfire
]]
ZoneCampfire = {
    -- Допустимые для зоны элементы
    elementTypes = {
        [ "player" ] = true
    }
}
setmetatable( ZoneCampfire, { __index = Zone } )

function ZoneCampfire:create( typeHash, position, id )
    if Zone.create( self, typeHash, position, id ) then
       
        return true
    end

    return false
end

function ZoneCampfire:destroy()
    Zone.destroy( self )
end

function ZoneCampfire:write( out )
    Zone.write( self, out )
end

function ZoneCampfire:onHit( element )
    
end

function ZoneCampfire:onLeave( element )
    
end

function ZoneCampfire:update( dt )
    
end

--[[
    ZoneGreen
]]
ZoneGreen = {
    -- Допустимые для зоны элементы
    elementTypes = {
        [ "player" ] = true
    }
}
setmetatable( ZoneGreen, { __index = Zone } )

function ZoneGreen:create( typeHash, position, id )
    if Zone.create( self, typeHash, position, id ) then
       
        return true
    end

    return false
end

function ZoneGreen:destroy()
    Zone.destroy( self )
end

function ZoneGreen:write( out )
    Zone.write( self, out )
end

function ZoneGreen:onHit( element )
    
end

function ZoneGreen:onLeave( element )
    
end

function ZoneGreen:update( dt )
    
end

function Zone_create( typeHash, posX, posY, posZ, radius, strength )
    local zoneSection = xrSettingsGetSection( typeHash )
    if not zoneSection then
        outputDebugString( "Зоны с данной секцией не было найдено", 2 )
        return
    end

    local class = g_ZoneHashes[ zoneSection.class ]
    if not class then
        outputDebugString( "Класса для данной зоны не было найдено", 1 )
        return
    end

    local id = g_Zones:allocate()

    local zone = {
        typeHash = typeHash,
        section = zoneSection,
        pos = Vector3( posX, posY, posZ ),
        radius = ( radius or tonumber( zoneSection.radius ) ) or 4,
        strength = tonumber( strength ) or 1,
        id = id
    }
    setmetatable( zone, { __index = class } )

    if zone:create() then
        g_Zones[ id ] = zone

        local data = {}
        zone:write( data )
        triggerClientEvent( EClientEvents.onZoneEvent, resourceRoot, ZONE_CREATE, id, data )

        return id
    end
end

function Zone_destroy( zone )  
    zone:destroy()
    g_Zones[ zone.id ] = nil

    triggerClientEvent( EClientEvents.onZoneEvent, resourceRoot, ZONE_DESTROY, zone.id )
end

local function onPlayerEnterLevel()
    local zones = {}
    for _, zone in pairs( g_Zones ) do
        local data = {}
        zone:write( data )
        table.insert( zones, data )
    end

    triggerClientEvent( source, EClientEvents.onZoneEvent, resourceRoot, ZONE_INIT, zones )        
end

local function onPlayerLeaveLevel()        
    triggerClientEvent( source, EClientEvents.onZoneEvent, resourceRoot, ZONE_PURGE )
end

local function onPlayerGamodeLeave()
    -- Оповещаем зоны о выходе игрока
    for _, zone in pairs( g_Zones ) do
        if zone:isElementWithin( source ) then
            table.removeValue( zone.nodesInside, source )
            zone:onLeave( source )
        end
    end
end

function onUpdateTimer( )    
    local dt = 100 / 1000
    
    for _, zone in pairs( g_Zones ) do
        zone:update( dt )
    end
end 

--[[
    Initialization
]]
function initZones()
    g_Zones = xrMakeIDTable()

    g_ZoneHashes[ _hashFn( "ZoneAnomaly" ) ] = ZoneAnomaly
    g_ZoneHashes[ _hashFn( "ZoneRadiation" ) ] = ZoneRadiation
    g_ZoneHashes[ _hashFn( "ZoneSector" ) ] = ZoneSector
    g_ZoneHashes[ _hashFn( "ZoneCampfire" ) ] = ZoneCampfire
    g_ZoneHashes[ _hashFn( "ZoneGreen" ) ] = ZoneGreen

    initAnomalies()
end

addEvent( "onCoreInitializing", false )
addEventHandler( "onCoreInitializing", root,
    function()
        triggerEvent( "onResourceInitialized", resourceRoot, resource )
    end
, false )

addEventHandler( "onCoreStarted", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )

        if not xrSettingsInclude( "teams.ltx" ) then
            return
        end	

        -- Загружаем только зоны
        if not xrSettingsInclude( "zones/zones.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации аномалий!", 2 )
            return
        end

        if not xrSettingsInclude( "items_only.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации предметов!", 2 )
            return
        end

        addEvent( EServerEvents.onPlayerEnterLevel, false )
        addEventHandler( EServerEvents.onPlayerEnterLevel, root, onPlayerEnterLevel )
        addEvent( EServerEvents.onPlayerLeaveLevel, false )
        addEventHandler( EServerEvents.onPlayerLeaveLevel, root, onPlayerLeaveLevel )
        addEvent( EServerEvents.onPlayerGamodeLeave, false )
        addEventHandler( EServerEvents.onPlayerGamodeLeave, root, onPlayerGamodeLeave )        

        initZones()  
        
        setTimer( onUpdateTimer, 100, 0 )
    end
)