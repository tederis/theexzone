xrSurge = {
    safeZones = {},
    state = false
}

SURGE_DURATION_SECS = 50*60
SURGE_PERIOD_REAL_SECS = 60*60*1

local function gameToRealSecs( secs )
    local gameSecDuration = ( G_TIME_DURATION / 1000 ) / 60
    return secs * gameSecDuration
end

local function realToGameSecs( secs )
    local gameSecDuration = ( 1000 * 60 ) / G_TIME_DURATION
    return secs * gameSecDuration
end

function xrSurge:addSafeZone( x, y, z, width, depth, height )
    local col = createColCuboid( x, y, z, width, depth, height )
    table.insert( self.safeZones, col )
end

function xrSurge:start()
    if self.state then 
        return
    end

    triggerEvent( EServerEvents.onThunderboltStarted, root )

    for _, player in ipairs( getElementsByType( "player" ) ) do
        if xrIsPlayerJoined( player ) then
            triggerClientEvent( player, EClientEvents.onClientThunderboltStarted, root, 0 )
        end
    end

    self.timer = setTimer(
        function()
            xrSurge:stop()
        end
    , gameToRealSecs( SURGE_DURATION_SECS ) * 1000, 1 )

    outputDebugString( "Выброс начат" )

    self.startTime = getRealTime().timestamp
    self.state = true
end

function xrSurge:stop()
    if not self.state then 
        return
    end

    if isTimer( self.timer ) then
        killTimer( self.timer )
    end

    triggerEvent( EServerEvents.onThunderboltFinished, root )
    triggerClientEvent( EClientEvents.onClientThunderboltFinished, root )

    local isPlayerInShelter = {}
    for _, col in ipairs( self.safeZones ) do
        for _, player in ipairs( getElementsWithinColShape( col ), "player" ) do
            isPlayerInShelter[ player ] = true
        end
    end

    for _, player in ipairs( getElementsByType( "player" ) ) do
        if not isPlayerInShelter[ player ] then
            exports.sp_player:xrKillPlayer( player )
        end
    end

    outputDebugString( "Выброс завершен" )

    self.startTime = nil
    self.state = false
end

function xrSurge:onPlayerJoin( player )
    if self.state then 
        local now = getRealTime().timestamp
        local timeElapsed = now - xrSurge.startTime
        local gameTimeElapsed = realToGameSecs( timeElapsed )

        triggerClientEvent( player, EClientEvents.onClientThunderboltStarted, root, gameTimeElapsed )
    end
end

--[[
    Exports
]]
function xrIsSurgeProceeding()
    return xrSurge.state == true
end

function xrGetSurgeRemainingSecs()
    if xrSurge.state then
        local now = getRealTime().timestamp
        local timeElapsed = now - xrSurge.startTime
        local surgeLength = gameToRealSecs( SURGE_DURATION_SECS )

        return math.clamp( 0, surgeLength, surgeLength - timeElapsed )
    end

    return false
end

local function onSurgePlayerGamodeJoin()
    xrSurge:onPlayerJoin( source )
end

local function onSurgeTimer()
    xrSurge:start()
end

--[[
    Init
]]
function initSurge()
    xrSurge:addSafeZone( -215.767, -127.873, -23.266 + 125, 6.19252, 7.51587, 2.90997 )
    xrSurge:addSafeZone( -208.93, -129.935, -22.6495 + 125, 4.63188, 3.61893, 2.7109 )
    xrSurge:addSafeZone( -60.6466, -71.7704, -10.312 + 125, 17.8893, 17.5191, 4.48889 )
    xrSurge:addSafeZone( 351.076, -91.8279, 11.7891 + 125, 51.2153, 68.034, 13.8539 )
    xrSurge:addSafeZone( -85.7415, 124.589, -7.92287 + 125, 29.8104, 66.1121, 17.3167 )

    addEvent( EServerEvents.onPlayerGamodeJoin, false )
    addEventHandler( EServerEvents.onPlayerGamodeJoin, root, onSurgePlayerGamodeJoin )

    setTimer( onSurgeTimer, SURGE_PERIOD_REAL_SECS * 1000, 0 )
end

addCommandHandler( "thunderbolt",
    function( player )
        if not hasObjectPermissionTo( player, "command.thunderbolt", false ) then
            outputChatBox( "У вас недостаточно прав для использования этой команды", player )
            return
        end

        xrSurge:start()
    end
)