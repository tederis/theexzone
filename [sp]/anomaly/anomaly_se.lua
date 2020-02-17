--[[
    ZoneAnomaly
]]
ART_SPAWN_PERIOD = 2 * 60000

xrLastThunderboltTime = nil

ZoneAnomaly = {
    -- Допустимые для зоны элементы
    elementTypes = {
        [ "player" ] = true,
        --[ "ped" ] = true
    }
}
setmetatable( ZoneAnomaly, { __index = Zone } )

function ZoneAnomaly:create()
    if Zone.create( self ) then
        self.currentTime = 0
        self.activated = false
        self.nodesInside = {}
        self.state = nil
        self.stateData = {}
        self.blowoutData = {}

        self:setState( ZONE_IDLE )
        
        return true
    end

    return false
end

function ZoneAnomaly:destroy()
    Zone.destroy( self )
end

function ZoneAnomaly:write( out )
    Zone.write( self, out )

    out[ ZA_STATE ] = self.state
end

function ZoneAnomaly:onHit( element )
    -- Игнорируем, если какой-то игрок уже есть в аномалии
    if #self.nodesInside > 1 then
        return
    end

    self.activated = true
    if self.state == ZONE_IDLE then       
        self:setState( ZONE_AWAKING )
    end
end

function ZoneAnomaly:onLeave( element )
    -- Деактивируем только когда игроков внутри не осталось
    if #self.nodesInside == 0 then        
        self.activated = false
    end
end

function ZoneAnomaly:affect()
    for _, element in ipairs( self.nodesInside ) do
        local dist = ( element.position - self.pos ):getLength()
        local power = self:getPower( dist, self.radius )

        triggerClientEvent( element, EClientEvents.onClientPlayerHit, element, PTH_SHOCK, power * 0.35, 3, false )
    end
end

function ZoneAnomaly:update( dt )
    local now = getTickCount()

	local section = self.section

	self.currentTime = self.currentTime + dt

    -- Обрабатываем выброс
    if self.state == ZONE_AWAKING then
        if self.currentTime > section.awaking_time / 1000 then
            self:setState( ZONE_BLOWOUT )
        end
    elseif self.state == ZONE_BLOWOUT then
        if self.currentTime > section.blowout_time / 1000 then
            self:setState( ZONE_ACCUMULATE )
        end

		local blowoutData = self.blowoutData

        -- Задержка аффекта на игрока и мир
        local delay = tonumber( blowout_explosion_time ) or 0
		if not blowoutData[ BLOWOUT_AFFECT ] and self.currentTime >= delay / 1000 then
            blowoutData[ BLOWOUT_AFFECT ] = true 

            self:affect()
        end
    elseif self.state == ZONE_ACCUMULATE then
        if self.currentTime > section.accamulate_time / 1000 then
            if self.activated then
                self:setState( ZONE_BLOWOUT )
            else
                self:setState( ZONE_IDLE )
            end
        end
	end
end

function ZoneAnomaly:setState( newState )
	local section = self.section

	if newState ~= self.state then
		self.state = newState
        self.currentTime = 0
        self.blowoutData = {}

        --outputDebugString( "Server state: " .. newState )
        
        triggerClientEvent( EClientEvents.onZoneEvent, resourceRoot, ZONE_STATE_CHANGE, self.id, newState )
	end
end

function ZoneAnomaly:onBoltHit( creator )
    if self.state == ZONE_IDLE then
        self:setState( ZONE_AWAKING )
    end
end

function Zone_onBoltHit( zoneId )
    local zone = g_Zones[ zoneId ]
    if zone then
        zone:onBoltHit( source )
    end
end

function onPlayerArtefactTake( zoneId, artTypeHash )
    local zone = g_Zones[ zoneId ]
    if not zone then
        return
    end

    local counterValue = exports.sp_player:xrGetPlayerInfo( client, EHashes.InfoAftefactCounter ) or 0
    if counterValue > ARTEFACT_NUM_QUOTA then
        outputDebugString( "Игрок не может собрать артефактов свыше квоты", 2 )
        return
    end

    -- Проверяем, действительно ли игрок мог взять артефакт
    local dist = ( zone.pos - client.position ):getLength()
    if dist <= zone.radius*2 then
        exports.xritems:xrContainerInsertItem( client, artTypeHash, EHashes.SlotBag, false )        
        exports.sp_player:xrSetPlayerInfo( client, EHashes.InfoAftefactCounter, counterValue + 1 )
    end
end

local function onThunderboltStarted()

end

local function onThunderboltFinished()
    xrLastThunderboltTime = getRealTime().timestamp

    for _, player in ipairs( getElementsByType( "player" ) ) do
        exports.sp_player:xrSetPlayerInfo( player, EHashes.InfoAftefactCounter, 0 )
        exports.sp_player:xrSetPlayerInfo( player, EHashes.InfoLastThunderboltTime, xrLastThunderboltTime )
    end    
end

function Anomaly_onPlayerEnterLevel()
    --[[
        Если за время отсутствия игрока произошел выброс - форсирусем респавн артефактов
    ]]
    if xrLastThunderboltTime then
        local counterValue = exports.sp_player:xrGetPlayerInfo( source, EHashes.InfoAftefactCounter ) or 0
        local lastPlayerThunderboltTime = exports.sp_player:xrGetPlayerInfo( source, EHashes.InfoLastThunderboltTime )
                
        if lastPlayerThunderboltTime and xrLastThunderboltTime > lastPlayerThunderboltTime then
            exports.sp_player:xrSetPlayerInfo( source, EHashes.InfoAftefactCounter, 0 )
            exports.sp_player:xrSetPlayerInfo( sourcer, EHashes.InfoLastThunderboltTime, xrLastThunderboltTime )
            counterValue = 0
        end

        local expectedCount = math.max( ARTEFACT_NUM_QUOTA - counterValue, 0 )
        triggerClientEvent( EClientEvents.onClientThunderboltForced, resourceRoot, expectedCount )
    end
end

--[[
    Init
]]
function initAnomalies()
    addEvent( EServerEvents.onPlayerEnterLevel, false )
    addEventHandler( EServerEvents.onPlayerEnterLevel, root, Anomaly_onPlayerEnterLevel )
    addEvent( EServerEvents.onAnomalyBoltHit, true )
    addEventHandler( EServerEvents.onAnomalyBoltHit, root, Zone_onBoltHit )
    addEvent( EServerEvents.onArtefactTake, true )
    addEventHandler( EServerEvents.onArtefactTake, resourceRoot, onPlayerArtefactTake, false )
    addEvent( EServerEvents.onThunderboltStarted, false )
    addEventHandler( EServerEvents.onThunderboltStarted, root, onThunderboltStarted )
    addEvent( EServerEvents.onThunderboltFinished, false )
    addEventHandler( EServerEvents.onThunderboltFinished, root, onThunderboltFinished )
end