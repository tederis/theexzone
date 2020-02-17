xrStreamedInAnomalies = {

}

--[[
    ZoneAnomaly
]]
ZoneAnomaly = {
    
}
setmetatable( ZoneAnomaly, { __index = Zone } )

function ZoneAnomaly:create()
    if Zone.create( self ) then
        self.currentTime = 0
        self.state = nil
        self.stateData = {}
        self.blowoutData = {}
        self.artefacts = {}
		self.lastArtefactIndex = 0
		
		for i = 1, 5 do
			self.stateData[ i ] = {}
		end

		return true
	end
	
	return false
end

function ZoneAnomaly:destroy()
    Zone.destroy( self )

    for state, data in pairs( self.stateData ) do
		exports["papi"]:xrGroupDestroy( data.effect )
		data.effect = nil

		if isElement( data.sound ) then
			stopSound( data.sound )
			data.sound = nil
		end
	end

	for _, artefact in pairs( self.artefacts ) do
		artefact:destroy()
	end

	table.removeValue( xrStreamedInAnomalies, self )
end

function ZoneAnomaly:load( zoneData )
	if not Zone.load( self, zoneData ) then
		return false
	end

	local state = zoneData[ ZA_STATE ]
	if type( state ) ~= "number" then
		return false
	end		

	self:setState( ZONE_IDLE )
	self:setState( state )
		
	return true
end

function ZoneAnomaly:playParticles( name )
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
function ZoneAnomaly:playSound( name, looped )
	if not self.streamedIn then
		return
	end

	if name:len() < 1 then
		outputDebugString( "Инвалидное название звука", 1 )
		return
	end

	local sound = playSound3D( name, self.pos, looped )
	if sound then
		setSoundMaxDistance( sound, 100 )
		addEventHandler( "onClientSoundStopped", sound, _onSoundStopped, false )

		return sound
	else
		outputDebugString( "Не можем найти звук", 2 )
	end
end

function ZoneAnomaly:playLight( radius, color, duration )
	if not self.streamedIn then
		return
	end

	local r, g, b = 255, 255, 255
	if color then
		r, g, b = color:getX(), color:getY(), color:getZ()
	end
	
	local index = exports.escape:xrCreatePointLight( 
		self.pos:getX(), self.pos:getY(), self.pos:getZ(), 
		r, g, b, 
		radius, tonumber( duration ) or -1, false
	)

	return index
end

function ZoneAnomaly:update( dt )
	local section = self.section

	self.currentTime = self.currentTime + dt

	-- Обрабатываем выброс
	if self.state == ZONE_BLOWOUT then
		local blowoutData = self.blowoutData
		
		-- Задержка создания частиц
		local delay = tonumber( section.blowout_particles_time ) or 0
		if not blowoutData[ BLOWOUT_PARTICLE ] and self.currentTime >= delay / 1000 then
			blowoutData[ BLOWOUT_PARTICLE ] = true

			self:playParticles( "Particle/" .. section.blowout_particles .. ".xml" )
		end

		-- Задержка создания света
		delay = tonumber( section.blowout_light_time ) or 0
		if not blowoutData[ BLOWOUT_LIGHT ] and self.currentTime >= delay / 1000 then
			blowoutData[ BLOWOUT_LIGHT ] = true

			self:playLight( tonumber( section.light_range ) or 6, section.light_color, tonumber( section.light_time ) or 1 )
		end

		-- Задержка звука
		delay = tonumber( section.blowout_sound_time ) or 0
		if not blowoutData[ BLOWOUT_SOUND ] and self.currentTime >= delay / 1000 then
			blowoutData[ BLOWOUT_SOUND ] = true

			self:playSound( "Sounds/" .. section.blowout_sound .. ".ogg", false )
		end

		-- Задержка аффекта на игрока и мир
		delay = tonumber( section.blowout_explosion_time ) or 0
		if not blowoutData[ BLOWOUT_AFFECT ] and self.currentTime >= delay / 1000 then
			blowoutData[ BLOWOUT_AFFECT ] = true

			-- TODO
		end
	end
end

function ZoneAnomaly:setState( newState )
	local section = self.section

	if newState ~= self.state then
		self.state = newState
		self.currentTime = 0
		self.blowoutData = {}

		--outputDebugString( "Client state: " .. newState )

		local stateData = self.stateData[ newState ]
		if newState == ZONE_IDLE then
			if not exports["papi"]:xrGroupExists( stateData.effect ) and section.idle_particles then
				stateData.effect = self:playParticles( "Particle/" .. section.idle_particles .. ".xml" )
			end

			if not isElement( stateData.sound ) and section.idle_sound then
				stateData.sound = self:playSound( "Sounds/" .. section.idle_sound .. ".ogg", true )
			end

			if not exports.escape:xrLightExists( stateData.light ) and section.idle_light == "on" then
				stateData.light = self:playLight( tonumber( section.idle_light_range ) or 6, section.idle_light_color )
			end
		elseif newState == ZONE_AWAKING then
			if not exports["papi"]:xrGroupExists( stateData.effect ) and section.awake_particles then
				stateData.effect = self:playParticles( "Particle/" .. section.awake_particles .. ".xml" )
			end

			if not isElement( stateData.sound ) and section.awake_sound then
				stateData.sound = self:playSound( "Sounds/" .. section.awake_sound .. ".ogg", true )
			end
		elseif newState == ZONE_ACCUMULATE then
			if not exports["papi"]:xrGroupExists( stateData.effect ) and section.accum_particles then
				stateData.effect = self:playParticles( "Particle/" .. section.accum_particles .. ".xml" )
			end

			if not isElement( stateData.sound ) and section.accum_sound then
				stateData.sound = self:playSound( "Sounds/" .. section.accum_sound .. ".ogg", true )
			end
		elseif newState == ZONE_BLOWOUT then
			--[[
				Перед выбросом мы должны удалить все что связано
				с фазой ожидания
			]]
			local idleData = self.stateData[ ZONE_IDLE ] or EMPTY_TABLE

			-- Останавливаем IDLE эффекты и звуки
			if idleData.effect then
				exports["papi"]:xrGroupDestroy( idleData.effect )
				idleData.effect = nil
			end
		
			if isElement( idleData.sound ) then
				stopSound( idleData.sound )
				idleData.sound = nil
			end
		
			exports.escape:xrLightDestroy( idleData.light )
			idleData.light = nil
		end
	end
end

function ZoneAnomaly:onEvent( operation, arg0 )
    -- id, newState
	if operation == ZONE_STATE_CHANGE then
		self:setState( arg0 )
	end
end

function ZoneAnomaly:onStreamedIn()
	local section = self.section
	local stateData = self.stateData[ ZONE_IDLE ]

	if not exports["papi"]:xrGroupExists( stateData.effect ) and section.idle_particles then
		stateData.effect = self:playParticles( "Particle/" .. section.idle_particles .. ".xml" )
	end

	if not isElement( stateData.sound ) and section.idle_sound then
		stateData.sound = self:playSound( "Sounds/" .. section.idle_sound .. ".ogg", true )
	end

	if not exports.escape:xrLightExists( stateData.light ) and section.idle_light == "on" then
		stateData.light = self:playLight( tonumber( section.idle_light_range ) or 6, section.idle_light_color )
	end

	table.insertIfNotExists( xrStreamedInAnomalies, self )
	
	for _, art in pairs( self.artefacts ) do
		art:onStreamedIn()
    end
end

function ZoneAnomaly:onStreamedOut()
	local section = self.section
	local stateData = self.stateData[ ZONE_IDLE ]

	if stateData.effect then
		exports["papi"]:xrGroupDestroy( stateData.effect )
		stateData.effect = nil
	end

	if isElement( stateData.sound ) then
		stopSound( stateData.sound )
		stateData.sound = nil
	end

	exports.escape:xrLightDestroy( stateData.light )
	stateData.light = nil

	table.removeValue( xrStreamedInAnomalies, self )
	
	for _, art in pairs( self.artefacts ) do
		art:onStreamedOut()
    end
end

function ZoneAnomaly:destroyArtefacts()
	for _, art in pairs( self.artefacts ) do
		art:destroy()
    end

    self.artefacts = {

	}
	
	return true
end

function ZoneAnomaly:spawnArtefacts()
	-- Запрещаем спавнить больше одного артефакта	
	if next( self.artefacts ) ~= nil then		
		return false
	end

    local artefacts = self.section.artefacts or EMPTY_TABLE
    if #artefacts > 0 then
        local randomHash = artefacts[ math.random( 1, #artefacts ) ]

		local artefact = Artefact.create( self, randomHash )
		if artefact then
			self.lastArtefactIndex = self.lastArtefactIndex + 1

			artefact.id = self.lastArtefactIndex

			self.artefacts[ self.lastArtefactIndex ] = artefact

			-- Debug
			--exports.escape:xrCreateBlip( "ui_common", "ui_pda2_secrets", 20, self.pos:getX(), self.pos:getY(), self.pos:getZ() )

			outputDebugString("Артефакт заспавнен")

			return true
		end
	end
	
	return false
end

function ZoneAnomaly:getArtefactCount()
	local num = 0
	for _, art in pairs( self.artefacts ) do
		num = num + 1
	end
	
	return num
end

function ZoneAnomaly:onArtefactTaken( element )
	local arts = self.artefacts

	local foundedHash = nil
	for artId, art in pairs( arts ) do
		if art.object == element then
			foundedHash = art.typeHash

			art:destroy()
			arts[ artId ] = nil
		end
    end

	if foundedHash then
		triggerServerEvent( EServerEvents.onArtefactTake, resourceRoot, self.id, foundedHash )
	end
end

local function doProcessThunderbolt( artsCount )
	local anomalies = {}
	local totalArtefactsNum = 0

	for _, zone in pairs( g_Zones ) do
		if zone.class == EHashes.ZoneAnomaly then
			local artefactsNum = zone:getArtefactCount()
			totalArtefactsNum = totalArtefactsNum + artefactsNum

			if artefactsNum < 1 then
				table.insert( anomalies, zone )
			end
		end
	end

	local count = math.min( math.max( artsCount - totalArtefactsNum, 0 ), #anomalies )
	for i = 1, count do
		local randIndex = math.random( 1, #anomalies )
		local anomaly = anomalies[ randIndex ]
		if anomaly and anomaly:spawnArtefacts() then
			table.remove( anomalies, randIndex )
		end
	end
end

local function onArtefactTake()
	local anomalyId = getElementData( source, "anomalyId", false )
	local zone = g_Zones[ anomalyId ]
	if zone then
		zone:onArtefactTaken( source )
	end
end

--[[
	Выброс только что завершен для всех игроков
]]
local function onThunderboltFinished()
	doProcessThunderbolt( ARTEFACT_NUM_QUOTA )
end

--[[
	Игрок присоеднинился к игре
]]
local function onThunderboltForced( expectedCount )
	doProcessThunderbolt( expectedCount )
end

--[[
    Utils
]]
function xrZoneFindArtefacts( x, y, z, radius )
    local radiusSqr = radius*radius
	local result = {}
    
	for _, zone in ipairs( xrStreamedInAnomalies ) do
		for artId, artefact in pairs( zone.artefacts ) do
			if artefact:isTimeToShow() then
				local lenSqr = ( artefact.x - x )^2 + ( artefact.y - y )^2 + ( artefact.z - z )^2
				if lenSqr <= radiusSqr then
					table.insert( result, artefact )
				end
			end
        end
	end

	return result
end

--[[
	Init
]]
function initAnomalies()
	addEvent( "onClientArtefactTake", false )
	addEventHandler( "onClientArtefactTake", resourceRoot, onArtefactTake )

	addEvent( EClientEvents.onClientThunderboltFinished, true )
	addEventHandler( EClientEvents.onClientThunderboltFinished, resourceRoot, onThunderboltFinished )
	addEvent( EClientEvents.onClientThunderboltForced, true )
	addEventHandler( EClientEvents.onClientThunderboltForced, resourceRoot, onThunderboltForced )
end
