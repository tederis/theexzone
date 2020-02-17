g_ZoneHashes = {

}

Zone = {

}
ZoneMT = {
    __index = Zone
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

g_Zones = {

}

xrPlayerZones = {
	-- Зоны, в которых игрок находится сейчас
}

function Zone:create()
	return true
end

function Zone:destroy()
	destroyElement( self.element )
end

function Zone:load( zoneData )
    local typeHash = zoneData[ ZA_TYPEHASH ]
	local posTbl = zoneData[ ZA_POS ]
	local id = zoneData[ ZA_ID ]
	local radius = zoneData[ ZA_RADIUS ]
	local strength = zoneData[ ZA_STRENGTH ]
	if type( typeHash ) ~= "number" or type( posTbl ) ~= "table" or type( id ) ~= "number" or type( radius ) ~= "number" or type( strength ) ~= "number" then
		outputDebugString( "Зона не была создана", 2 )
		return false
	end

	local zoneSection = xrSettingsGetSection( typeHash )
	if not zoneSection then
		outputDebugString( "Такой секции зоны не существует!", 2 )
		return false
	end
	
	self.typeHash = typeHash
	self.class = zoneSection.class
	self.radius = radius
	self.strength = strength
	self.id = id
	self.section = zoneSection
	self.pos = Vector3( unpack( posTbl ) )

	-- Элемент для кросс-ресурсной работы
	local element = createElement( "zone" )
	setElementPosition( element, self.pos )
	setElementData( element, "cl", typeHash, false )
	setElementData( element, "type", zoneSection.class, false )
	setElementData( element, "radius", radius, false )
	setElementData( element, "strength", strength, false )
	triggerEvent( "onClientZoneCreated", element )
	self.element = element

	local colshape = zoneData[ ZA_COLSHAPE ]
	if colshape then
		self.col = colshape

		-- Форсируем событие
		--[[if isElementWithinColShape( localPlayer, colshape ) then
			self:onHit( localPlayer )
		end]]
	end

	return true
end

function Zone:getDistTo( element )
	local dist = 0
	if self.section.col_shape == "circle" then
		local x, y = getElementPosition( element )
		local x1, y1 = self.pos:getX(), self.pos:getY()
		dist = math.sqrt( math.pow( x - x1, 2 ) + math.pow( y - y1, 2 ) )
	else
		dist = ( element.position - self.pos ):getLength()
	end

	return dist
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

function Zone:onEvent( operation, data )

end

function Zone:onAffect( dt )

end

function Zone:onHit( element )

end

function Zone:onLeave( element )
	
end

function Zone:onStreamedIn()

end

function Zone:onStreamedOut()

end

--[[
    ZoneRadiation
]]
ZoneRadiation = {

}
setmetatable( ZoneRadiation, { __index = Zone } )

function ZoneRadiation:create()
	if Zone.create( self ) then
		self.timeElapsed = 0

        return true      
	end
	
	return false
end

function ZoneRadiation:destroy()
    Zone.destroy( self )
end

function ZoneRadiation:load( zoneData )
    if not Zone.load( self, zoneData ) then
		return false
	end

	return true
end

function ZoneRadiation:onAffect( dt )
	self.timeElapsed = self.timeElapsed + dt
    if self.timeElapsed < 1 then
        return
	end
	self.timeElapsed = 0

	local dist = self:getDistTo( localPlayer )
	local power = self:getPower( dist, self.radius )

	triggerEvent( EClientEvents.onClientPlayerHit, localPlayer, PHT_RADIATION, power, 3, false )
end

function ZoneRadiation:update( dt )   
end

--[[
    ZoneCampfire
]]
ZoneCampfire = {

}
setmetatable( ZoneCampfire, { __index = Zone } )

function ZoneCampfire:create()
	if Zone.create( self ) then
        return true      
	end
	
	return false
end

function ZoneCampfire:destroy()
	Zone.destroy( self )
	
	exports["papi"]:xrGroupDestroy( self.idleEffect )
	self.idleEffect = nil

	if isElement( self.idleSnd ) then
		stopSound( self.idleSnd )
		self.idleSnd = nil
	end

	exports.escape:xrLightDestroy( self.idleLight )
	self.idleLight = nil

	destroyElement( self.obj )
	self.obj = nil
end


function ZoneCampfire:load( zoneData )
    if not Zone.load( self, zoneData ) then
		return false
	end

	setElementData( self.element, "int", EHashes.CampfireClass )

	self.obj = createObject( 3781, self.pos - Vector3( 0, 0, 0.5 ) )
	
	return true
end

function ZoneCampfire:update( dt )
   
end

function ZoneCampfire:onHit( element )
	exports.sp_player:PlayerAffector_applyAffect( EAT_HEALTH_RSPD, 0.004, self.typeHash )
	exports.sp_hud_real_new:xrSendPlayerHelpString( localPlayer, HSC_CAMPFIRE_AREA )	
end

function ZoneCampfire:onLeave( element )
	exports.sp_player:PlayerAffector_removeAffect( EAT_HEALTH_RSPD, 0.004, self.typeHash )
end

function ZoneCampfire:onEvent( operation, arg0 )
	
end

function ZoneCampfire:playLight( radius )
	if not self.streamedIn then
		return
	end

	local index = exports.escape:xrCreatePointLight( 
		self.pos:getX(), self.pos:getY(), self.pos:getZ(), 
		255, 130, 50, 
		radius, -1, false
	)

	return index
end

function ZoneCampfire:playParticles( name )
	if not self.streamedIn then
		return
	end

	local index = exports["papi"]:xrGroupPlay( 
		name, 
		self.pos:getX(), self.pos:getY(), self.pos:getZ(), 
		0, 0, 0,
		false 
	)
	if not index then
		outputDebugString( "Частицы не были созданы!", 2 )
	end

	return index
end

-- Когда звук завершился - всегда удаляем его
local _onSoundStopped = function( reason )
	if reason == "finished" then
		stopSound( source )
	end
end
function ZoneCampfire:playSound( name, looped )
	if not self.streamedIn then
		return
	end

	if name:len() < 1 then
		outputDebugString( "Инвалидное название звука", 1 )
		return
	end

	local sound = playSound3D( name, self.pos, looped )
	if sound then
		setSoundMaxDistance( sound, 50 )
		addEventHandler( "onClientSoundStopped", sound, _onSoundStopped, false )

		return sound
	else
		outputDebugString( "Не можем найти звук", 2 )
	end
end

function ZoneCampfire:onStreamedIn()
	local section = self.section	

	if not exports["papi"]:xrGroupExists( self.idleEffect ) and section.idle_particles then
		self.idleEffect = self:playParticles( "Particle/" .. section.idle_particles .. ".xml" )
	end

	if not isElement( self.idleSnd ) and section.idle_sound then
		self.idleSnd = self:playSound( "Sounds/" .. section.idle_sound .. ".ogg", true )
	end

	if not exports.escape:xrLightExists( self.idleLight ) and section.idle_light == "on" then
		self.idleLight = self:playLight( tonumber( section.idle_light_range ) or 6 )
	end
end

function ZoneCampfire:onStreamedOut()
	if self.idleEffect then
		exports["papi"]:xrGroupDestroy( self.idleEffect )
		self.idleEffect = nil
	end

	if isElement( self.idleSnd ) then
		stopSound( self.idleSnd )
		self.idleSnd = nil
	end

	if self.idleLight then
		exports.escape:xrLightDestroy( self.idleLight )
		self.idleLight = nil
	end
end

--[[
    ZoneGreen
]]
ZoneGreen = {

}
setmetatable( ZoneGreen, { __index = Zone } )

function ZoneGreen:create()
	if Zone.create( self ) then
        return true      
	end
	
	return false
end

function ZoneGreen:destroy()
	Zone.destroy( self )
end


function ZoneGreen:load( zoneData )
    if not Zone.load( self, zoneData ) then
		return false
	end

	local typeHash = self.section.team
	setElementData( self.element, "zowner", typeHash, false )
	
	return true
end

function ZoneGreen:update( dt )
   
end

function ZoneGreen:onHit( element )
	setElementData( localPlayer, "damageProof", true, false )
	exports.sp_weapon:xrToggleFire( false )

	for _, player in ipairs( getElementsByType( "player" ) ) do
		setElementCollidableWith( localPlayer, player, false )
	end
end

function ZoneGreen:onLeave( element )
	setElementData( localPlayer, "damageProof", false, false )
	exports.sp_weapon:xrToggleFire( true )

	for _, player in ipairs( getElementsByType( "player" ) ) do
		setElementCollidableWith( localPlayer, player, true )
	end
end

function ZoneGreen:onEvent( operation, arg0 )
	
end

function xrZoneFindNearest( typeHash )
	local minZone
	local minDist

	for _, zone in ipairs( xrPlayerZones ) do
		if zone.class == typeHash then
			local dist = zone:getDistTo( localPlayer )
			if not minDist or dist < minDist then
				minDist = dist
				minZone = zone
			end
		end
	end

	if minZone then
		return minZone, minDist
	end
end

function xrGetPlayerZoneElement( player, typeHash )
	if player ~= localPlayer then
		return false
	end

	for _, zone in ipairs( xrPlayerZones ) do
		if zone.class == typeHash then
			return zone.element
		end
	end

	return false
end

function xrIsPlayerWithinGreenZone( player )
	if player ~= localPlayer then
		return false
	end

	local team = getPlayerTeam( player )
	local teamHash = getElementData( team, "cl", false )

	local greenHash = EHashes.ZoneGreen
	for _, zone in ipairs( xrPlayerZones ) do
		if zone.class == greenHash and ( not zone.section.team or zone.section.team == teamHash ) then
			return true
		end
	end

	return false
end

function xrGetPlayerZoneInfluence( typeHash )
	local minZone, minDist = xrZoneFindNearest( typeHash )
	if minZone then
		local power = minZone:getPower( minDist, minZone.radius )	
		return power
	end

	return 0
end

function xrZoneGetAttribute( zoneId, key )
	local zone = g_Zones[ zoneId ]
	if zone then
		return zone[ key ]
	end
end

function Zone_create( zoneData )
	local zoneSection = xrSettingsGetSection( zoneData[ ZA_TYPEHASH ] )
    if not zoneSection then
        outputDebugString( "Зоны с данной секцией не было найдено", 2 )
        return
    end

    local class = g_ZoneHashes[ zoneSection.class ]
    if not class then
        outputDebugString( "Класса для данной зоны не было найдено", 1 )
        return
	end
	

    local zone = {
		
    }
    setmetatable( zone, { __index = class } )

	if zone:create() and zone:load( zoneData ) then
		g_Zones[ zone.id ] = zone
		g_Streamer:pushItem( zone )
		
		if isElementWithinColShape( localPlayer, zone.col ) then
			table.insertIfNotExists( xrPlayerZones, zone )
			zone:onHit( localPlayer )
		end
    end
end

function Zone_destroy( zoneId )
	local zone = g_Zones[ zoneId ]
	if zone then
		g_Streamer:removeItem( zone )
		table.removeValue( xrPlayerZones, zone )
		zone:destroy()		
		g_Zones[ zoneId ] = nil
	end
end

local _flip = true
local _lastDT = 0
function onZoneUpdate( dt )
	dt = dt / 1000
	
	-- Обновление на частоте вдвое меньшей среднему FPS
	if _flip then
		local currentDt = _lastDT + dt

		for _, zone in pairs( g_Zones ) do
			if zone.streamedIn then
				zone:update( currentDt )
			end
		end

		for _, zone in ipairs( xrPlayerZones ) do
			if zone.streamedIn then
				zone:onAffect( currentDt )
			end
		end
		
		ClientDetector:process( currentDt )
		SoundRepeater:update( currentDt )

		local x, y, z = getElementPosition( localPlayer )
		g_Streamer:update( x, y, z )
	end

	ClientDetector:render()
	
	_flip = not _flip
	_lastDT = dt
end 

local function onZoneEvent( operation, zoneId, arg0 )
	-- id, data
	if operation == ZONE_CREATE then
		Zone_create( arg0 )
	
	-- id
	elseif operation == ZONE_DESTROY then
		Zone_destroy( zoneId )

	-- zones
	elseif operation == ZONE_INIT then
		for _, zoneData in ipairs( zoneId ) do
			Zone_create( zoneData )
		end
	elseif operation == ZONE_PURGE then
		for id, zone in pairs( g_Zones ) do
			Zone_destroy( id )
		end
		g_Zones = {}
	else
		local zone = g_Zones[ zoneId ]
		if zone then
			zone:onEvent( operation, arg0 )
		end
	end
end

function onPlayerZoneHit( colshape, matchingDimension )
	local zoneId = getElementData( colshape, "znid", false )
	local zone = g_Zones[ zoneId ]
	if zone and matchingDimension then
		table.insertIfNotExists( xrPlayerZones, zone )
		zone:onHit( source )
	end
end

function onPlayerZoneLeave( colshape, matchingDimension )
	local zoneId = getElementData( colshape, "znid", false )
	local zone = g_Zones[ zoneId ]
	if zone and matchingDimension then
		table.removeValue( xrPlayerZones, zone )
		zone:onLeave( source )
	end
end

addEvent( "onClientCoreStarted", false )
addEventHandler( "onClientCoreStarted", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
		xrIncludeModule( "global.lua" )
		xrIncludeModule( "streamer.lua" )
  
        -- Загружаем только зоны
        if not xrSettingsInclude( "zones/zones.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации аномалий!", 2 )
            return
		end
		
		if not xrSettingsInclude( "items_only.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации предметов!", 2 )
            return
		end

		if not xrSettingsInclude( "teams.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации команд!", 2 )
            return
		end
		
		g_Streamer = xrStreamer_new( 50, 1 )

		addEvent( "onClientZoneCreated", false )

		addEvent( EClientEvents.onZoneEvent, true )
		addEventHandler( EClientEvents.onZoneEvent, resourceRoot, onZoneEvent, false )
		addEventHandler( "onClientPreRender", root, onZoneUpdate, false )
		addEventHandler( "onClientElementColShapeHit", localPlayer, onPlayerZoneHit, false )
		addEventHandler( "onClientElementColShapeLeave", localPlayer, onPlayerZoneLeave, false )

		g_ZoneHashes[ _hashFn( "ZoneAnomaly" ) ] = ZoneAnomaly
		g_ZoneHashes[ _hashFn( "ZoneRadiation" ) ] = ZoneRadiation
		g_ZoneHashes[ _hashFn( "ZoneSector" ) ] = ZoneSector
		g_ZoneHashes[ _hashFn( "ZoneCampfire" ) ] = ZoneCampfire
		g_ZoneHashes[ _hashFn( "ZoneGreen" ) ] = ZoneGreen

		local col_floors = engineLoadCOL ( "models/prop_barrel2_fire.col" )
		engineReplaceCOL ( col_floors, 3781 )
		local txd_floors = engineLoadTXD ( "models/prop_barrel2_fire.txd" )
		engineImportTXD ( txd_floors, 3781 )
		local dff_floors = engineLoadDFF ( "models/prop_barrel2_fire.dff" )
		engineReplaceModel ( dff_floors, 3781 )

		local col_floors = engineLoadCOL ( "models/art_blue.col" )
		engineReplaceCOL ( col_floors, 3782 )
		local txd_floors = engineLoadTXD ( "models/art_blue.txd" )
		engineImportTXD ( txd_floors, 3782 )
		local dff_floors = engineLoadDFF ( "models/art_blue.dff" )
		engineReplaceModel ( dff_floors, 3782 )

		local col_floors = engineLoadCOL ( "models/art_flash.col" )
		engineReplaceCOL ( col_floors, 3783 )
		local txd_floors = engineLoadTXD ( "models/art_flash.txd" )
		engineImportTXD ( txd_floors, 3783 )
		local dff_floors = engineLoadDFF ( "models/art_flash.dff" )
		engineReplaceModel ( dff_floors, 3783 )

		local col_floors = engineLoadCOL ( "models/art_blood.col" )
		engineReplaceCOL ( col_floors, 3786 )
		local txd_floors = engineLoadTXD ( "models/art_blood.txd" )
		engineImportTXD ( txd_floors, 3786 )
		local dff_floors = engineLoadDFF ( "models/art_blood.dff" )
		engineReplaceModel ( dff_floors, 3786 )

		local col_floors = engineLoadCOL ( "models/art_balon.col" )
		engineReplaceCOL ( col_floors, 3785 )
		local txd_floors = engineLoadTXD ( "models/art_balon.txd" )
		engineImportTXD ( txd_floors, 3785 )
		local dff_floors = engineLoadDFF ( "models/art_balon.dff" )
		engineReplaceModel ( dff_floors, 3785 )

		xrInitDetectors()
		initArtefacts()
		initBolts()
		initAnomalies()
    end
)